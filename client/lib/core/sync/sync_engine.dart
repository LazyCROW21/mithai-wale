import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../network/api_client.dart';
import 'sync_store.dart';

enum SyncPhase { idle, syncing, resyncing, offline, error }

@immutable
class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.pending = 0,
    this.failed = 0,
    this.lastSyncAt,
    this.downloaded = 0,
    this.dataRevision = 0,
    this.message,
  });

  final SyncPhase phase;

  /// Local changes waiting to be uploaded.
  final int pending;

  /// Changes the server rejected.
  final int failed;
  final DateTime? lastSyncAt;

  /// Records downloaded so far during a full re-sync.
  final int downloaded;

  /// Bumped whenever synced data changed locally from the server; view models
  /// that don't watch Hive directly reload on it.
  final int dataRevision;
  final String? message;

  bool get isBusy => phase == SyncPhase.syncing || phase == SyncPhase.resyncing;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pending,
    int? failed,
    DateTime? lastSyncAt,
    int? downloaded,
    int? dataRevision,
    String? Function()? message,
  }) =>
      SyncStatus(
        phase: phase ?? this.phase,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        downloaded: downloaded ?? this.downloaded,
        dataRevision: dataRevision ?? this.dataRevision,
        message: message != null ? message() : this.message,
      );
}

/// Drains the outbox to the server and pulls server changes.
///
/// Runs on sign-in, every [interval] while the app is in the foreground, when
/// the app resumes, and shortly after any local change.
class SyncEngine extends StateNotifier<SyncStatus> with WidgetsBindingObserver {
  SyncEngine({this.interval = const Duration(seconds: 60)}) : super(const SyncStatus());

  static const pushBatch = 100;
  static const pullBatch = 500;

  final Duration interval;
  SyncStore? _store;
  ApiClient? _api;
  Timer? _timer;
  Timer? _debounce;
  bool _running = false;
  bool _rerun = false;
  bool _started = false;

  SyncStore get store => _store!;

  SyncStatus get current => state;

  /// Called once at startup, before any sign-in.
  void attach(SyncStore store, ApiClient api) {
    _store = store;
    _api = api;
    store.onEnqueue = () {
      _refreshCounts();
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 2), () => syncNow());
    };
    _refreshCounts();
  }

  /// Starts syncing for a signed-in user. Wipes local data if it belonged to
  /// someone else. [defaultShopId] seeds the shop new orders are written to.
  Future<void> start({required String owner, String? defaultShopId}) async {
    await store.claimFor(owner);
    if (store.activeShopId == null && defaultShopId != null) {
      await store.setMeta('activeShopId', defaultShopId);
    }
    final last = store.meta('lastSyncAt');
    state = state.copyWith(lastSyncAt: last == null ? null : DateTime.tryParse(last));
    _refreshCounts();
    if (!_started) {
      WidgetsBinding.instance.addObserver(this);
      _started = true;
    }
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncNow());
    unawaited(syncNow());
  }

  /// Stops syncing but keeps local data (e.g. session expired: the same user
  /// signing back in continues with their pending changes).
  void stop() {
    _timer?.cancel();
    _debounce?.cancel();
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
      _started = false;
    }
  }

  /// Explicit sign-out: stop and wipe this user's local data.
  Future<void> stopAndWipe() async {
    stop();
    await store.wipe();
    state = SyncStatus(dataRevision: state.dataRevision + 1);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(syncNow());
  }

  void _refreshCounts() {
    if (_store == null) return;
    state = state.copyWith(pending: store.pendingCount, failed: store.failedCount);
  }

  void _dataChanged() => state = state.copyWith(dataRevision: state.dataRevision + 1);

  /// Push then pull. Safe to call any time; concurrent calls coalesce.
  Future<void> syncNow() async {
    if (_store == null || _api == null || state.phase == SyncPhase.resyncing) return;
    if (_running) {
      _rerun = true;
      return;
    }
    _running = true;
    try {
      do {
        _rerun = false;
        state = state.copyWith(phase: SyncPhase.syncing);
        await _ensureDevice();
        await _pushAll();
        final resync = await _pullAll();
        if (resync) {
          _running = false;
          await fullResync(discardPending: false);
          return;
        }
        final now = DateTime.now();
        await store.setMeta('lastSyncAt', now.toIso8601String());
        state = state.copyWith(phase: SyncPhase.idle, lastSyncAt: now, message: () => null);
      } while (_rerun);
    } on ApiException catch (e) {
      state = state.copyWith(
        phase: e.isNetwork ? SyncPhase.offline : SyncPhase.error,
        message: () => e.message,
      );
    } catch (e, st) {
      debugPrint('Sync failed: $e\n$st');
      state = state.copyWith(phase: SyncPhase.error, message: () => '$e');
    } finally {
      _running = false;
      _refreshCounts();
    }
  }

  Future<void> _ensureDevice() async {
    if (store.deviceCode != null) return;
    final j = await _api!.post('/sync/devices', body: {'deviceId': store.deviceId}) as Map<String, dynamic>;
    await store.setMeta('deviceCode', j['code'] as String);
  }

  /// Uploads the outbox in batches until it is empty.
  Future<void> _pushAll() async {
    while (true) {
      final batch = store.peek(pushBatch);
      if (batch.isEmpty) return;
      final res = await _api!.post('/sync/push', body: {
        'deviceId': store.deviceId,
        'ops': [for (final (_, op) in batch) _wireOp(op)],
      }) as Map<String, dynamic>;

      final results = (res['results'] as List).cast<Map<String, dynamic>>();
      var changed = false;
      final done = <dynamic>[];
      for (var i = 0; i < batch.length && i < results.length; i++) {
        final (key, op) = batch[i];
        final r = results[i];
        final collection = op['collection'] as String;
        final id = op['id'] as String;
        switch (r['status']) {
          case 'applied':
          case 'duplicate':
            done.add(key);
            if (r['doc'] is Map) {
              await store.putServerDoc(collection, Map<String, dynamic>.from(r['doc'] as Map));
              changed = true;
            } else if (r['updatedAt'] != null && op['op'] != 'delete') {
              await store.stampServerUpdatedAt(collection, id, r['updatedAt'] as String);
            }
          case 'merged':
          case 'conflict':
            done.add(key);
            if (r['doc'] is Map) {
              await store.putServerDoc(collection, Map<String, dynamic>.from(r['doc'] as Map));
              changed = true;
            }
            if (r['status'] == 'conflict') {
              await store.markFailed(key, op, (r['error'] as Map?)?.cast<String, dynamic>());
              done.remove(key);
            }
          default: // rejected
            if ((r['error'] as Map?)?['code'] == 'INTERNAL') {
              continue; // server hiccup: keep it queued and retry later
            }
            if (r['doc'] is Map) {
              await store.putServerDoc(collection, Map<String, dynamic>.from(r['doc'] as Map));
              changed = true;
            }
            await store.markFailed(key, op, (r['error'] as Map?)?.cast<String, dynamic>());
        }
      }
      await store.removeOps(done);
      _refreshCounts();
      if (changed) _dataChanged();
      // Everything left in this batch was retried-later; stop to avoid a hot loop.
      if (store.peek(1).isNotEmpty && store.peek(1).first.$1 == batch.first.$1) return;
    }
  }

  static Map<String, dynamic> _wireOp(Map<String, dynamic> op) {
    final o = Map<String, dynamic>.from(op)..remove('queuedAt');
    return o;
  }

  /// Pulls changes page by page into the live boxes. Returns true if the
  /// server asked for a full re-sync.
  Future<bool> _pullAll() async {
    while (true) {
      final since = store.meta('since');
      final page = await _api!.get('/sync/pull', query: {
        'limit': '$pullBatch',
        'since': ?since,
        if (since != null) 'afterId': store.meta('afterId') ?? '',
        if (store.meta('scope') != null) 'scope': store.meta('scope')!,
      }) as Map<String, dynamic>;
      if (page['resync'] == true) return true;

      var changed = false;
      final changes = (page['changes'] as Map).cast<String, dynamic>();
      for (final entry in changes.entries) {
        if (!SyncCollections.all.contains(entry.key)) continue;
        for (final doc in (entry.value as List).cast<Map<String, dynamic>>()) {
          // Local edits waiting to upload win until the server answers them.
          if (store.hasPending(entry.key, doc['_id'] as String)) continue;
          await store.putServerDoc(entry.key, doc);
          changed = true;
        }
      }
      await _saveCursor(page);
      if (changed) _dataChanged();
      if (page['hasMore'] != true) return false;
    }
  }

  Future<void> _saveCursor(Map<String, dynamic> page) async {
    final next = page['next'] as Map?;
    if (next != null) {
      await store.setMeta('since', next['since'] as String);
      await store.setMeta('afterId', (next['afterId'] as String?) ?? '');
    }
    await store.setMeta('scope', page['scope'] as String?);
  }

  /// Replaces all local synced data with a fresh download from the server.
  ///
  /// Pending changes are uploaded first unless [discardPending]. Data is
  /// downloaded into temporary boxes and swapped in only when complete, so an
  /// interrupted re-sync leaves the current data intact.
  Future<void> fullResync({required bool discardPending}) async {
    if (_store == null || _api == null) return;
    while (_running) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    _running = true;
    _timer?.cancel();
    state = state.copyWith(phase: SyncPhase.resyncing, downloaded: 0, message: () => null);
    final temps = <String, Box<Map>>{};
    try {
      await _ensureDevice();
      if (discardPending) {
        await store.removeOps(store.peek(1 << 30).map((e) => e.$1));
      } else {
        await _pushAll();
        if (store.pendingCount > 0) {
          throw const ApiException('Some changes could not be uploaded yet', isNetwork: true);
        }
      }

      for (final c in SyncCollections.all) {
        temps[c] = await Hive.openBox<Map>('${c}__resync');
        await temps[c]!.clear();
      }
      String? since, afterId, scope;
      var downloaded = 0;
      while (true) {
        final page = await _api!.get('/sync/pull', query: {
          'limit': '$pullBatch',
          'since': ?since,
          if (since != null) 'afterId': afterId ?? '',
        }) as Map<String, dynamic>;
        final changes = (page['changes'] as Map).cast<String, dynamic>();
        for (final entry in changes.entries) {
          final temp = temps[entry.key];
          if (temp == null) continue;
          for (final doc in (entry.value as List).cast<Map<String, dynamic>>()) {
            await store.putServerDoc(entry.key, doc, into: temp);
            downloaded++;
          }
        }
        state = state.copyWith(downloaded: downloaded);
        final next = page['next'] as Map?;
        since = next?['since'] as String? ?? since;
        afterId = next?['afterId'] as String? ?? afterId;
        scope = page['scope'] as String?;
        if (page['hasMore'] != true) break;
      }

      // Swap: the download is complete, replace live data.
      for (final c in SyncCollections.all) {
        final live = store.box(c);
        final fresh = temps[c]!.toMap();
        await live.clear();
        await live.putAll(fresh);
      }
      await store.setMeta('since', since);
      await store.setMeta('afterId', afterId ?? '');
      await store.setMeta('scope', scope);
      final now = DateTime.now();
      await store.setMeta('lastSyncAt', now.toIso8601String());
      state = state.copyWith(phase: SyncPhase.idle, lastSyncAt: now, message: () => null);
      _dataChanged();
    } on ApiException catch (e) {
      state = state.copyWith(phase: e.isNetwork ? SyncPhase.offline : SyncPhase.error, message: () => e.message);
      rethrow;
    } finally {
      for (final t in temps.values) {
        await t.deleteFromDisk();
      }
      _running = false;
      _refreshCounts();
      _timer = Timer.periodic(interval, (_) => syncNow());
    }
  }

  Future<void> clearFailed() async {
    await store.clearFailed();
    _refreshCounts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}

/// App-wide engine (also reached from repositories and the auth flow).
final SyncEngine syncEngine = SyncEngine();

final syncStatusProvider = StateNotifierProvider<SyncEngine, SyncStatus>((ref) => syncEngine);
