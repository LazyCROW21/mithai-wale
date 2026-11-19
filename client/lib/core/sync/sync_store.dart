import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'ids.dart';

/// Names of synced collections. They match the server collection names.
abstract final class SyncCollections {
  static const categories = 'categories';
  static const menuItems = 'menu_items';
  static const orders = 'orders';
  static const payments = 'payments';
  static const inventoryItems = 'inventory_items';
  static const shops = 'shops';

  static const all = [categories, menuItems, orders, payments, inventoryItems, shops];
}

/// Local key holding the server's `updatedAt` for a record (sent back as
/// `baseUpdatedAt` so the server can detect concurrent edits).
const kServerUpdatedAt = '_updatedAt';

/// Fields kept only on this device and never sent to the server.
const _localOnlyFields = {'id', 'imageBytes', 'imageBase64', kServerUpdatedAt, 'shopId'};

/// Local persistence for offline-first sync.
///
/// - One Hive box per synced collection (records keyed by string id).
/// - An ordered **outbox** of pending operations. Repositories write the
///   record and enqueue the op together; the [SyncEngine] drains it.
/// - A **failed** box for ops the server rejected (they never block the queue).
/// - A **meta** box: pull cursor, device id/code, daily token counter, owner.
class SyncStore {
  SyncStore._(this._boxes, this._outbox, this._failed, this._meta);

  static const _metaBox = 'sync_meta';
  static const _outboxBox = 'sync_outbox';
  static const _failedBox = 'sync_failed';

  final Map<String, Box<Map>> _boxes;
  final Box<Map> _outbox;
  final Box<Map> _failed;
  final Box<String> _meta;

  /// Called after every enqueue so the engine can schedule a push.
  void Function()? onEnqueue;

  static Future<SyncStore> open() async {
    final boxes = <String, Box<Map>>{
      for (final c in SyncCollections.all) c: await Hive.openBox<Map>(c),
    };
    return SyncStore._(
      boxes,
      await Hive.openBox<Map>(_outboxBox),
      await Hive.openBox<Map>(_failedBox),
      await Hive.openBox<String>(_metaBox),
    );
  }

  Box<Map> box(String collection) => _boxes[collection]!;

  // ── Meta ──────────────────────────────────────────────────────────────────

  String? meta(String key) => _meta.get(key);
  Future<void> setMeta(String key, String? value) =>
      value == null ? _meta.delete(key) : _meta.put(key, value);

  /// Stable per-install id, survives sign-outs.
  String get deviceId {
    var id = _meta.get('deviceId');
    if (id == null) {
      id = uuidV4();
      _meta.put('deviceId', id);
    }
    return id;
  }

  /// Server-assigned device code (A, B, …) for order tokens; null until registered.
  String? get deviceCode => _meta.get('deviceCode');

  /// Shop new orders/payments are written to (franchise admin can switch it).
  String? get activeShopId => _meta.get('activeShopId');

  /// Next daily order token `<deviceCode>-<n>`; the counter resets every day.
  Future<({String id, String token, String tokenDate})> nextOrderIdentity() async {
    final today = localDateKey(DateTime.now());
    final seq = _meta.get('tokenDate') == today ? int.parse(_meta.get('tokenSeq') ?? '0') + 1 : 1;
    await _meta.put('tokenDate', today);
    await _meta.put('tokenSeq', '$seq');
    final token = '${deviceCode ?? 'X'}-$seq';
    // Readable and globally unique: token + random suffix.
    return (id: '#$token-${randomId(6).toUpperCase()}', token: token, tokenDate: today);
  }

  // ── Outbox ────────────────────────────────────────────────────────────────

  int get pendingCount => _outbox.length;
  int get failedCount => _failed.length;
  List<Map> get failedOps => _failed.values.toList();

  /// First [limit] pending ops in order, with their outbox keys.
  List<(dynamic, Map<String, dynamic>)> peek(int limit) => _outbox.keys
      .take(limit)
      .map((k) => (k, Map<String, dynamic>.from(_outbox.get(k)!)))
      .toList();

  bool hasPending(String collection, String id) =>
      _outbox.values.any((o) => o['collection'] == collection && o['id'] == id);

  Future<void> removeOps(Iterable<dynamic> keys) => _outbox.deleteAll(keys);

  Future<void> markFailed(dynamic key, Map<String, dynamic> op, Map<String, dynamic>? error) async {
    await _failed.add({...op, 'error': error, 'failedAt': DateTime.now().toIso8601String()});
    await _outbox.delete(key);
  }

  Future<void> clearFailed() => _failed.clear();

  (dynamic, Map<String, dynamic>)? _findPending(String collection, String id, String op) {
    for (final k in _outbox.keys) {
      final o = _outbox.get(k)!;
      if (o['collection'] == collection && o['id'] == id && o['op'] == op) {
        return (k, Map<String, dynamic>.from(o));
      }
    }
    return null;
  }

  Future<void> _add(Map<String, dynamic> op) async {
    await _outbox.add({'opId': uuidV4(), 'queuedAt': DateTime.now().toIso8601String(), ...op});
    onEnqueue?.call();
  }

  /// Local ISO date-time without an offset (how the app stores dates).
  static final _localIso = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?$');

  /// UTC ISO date-time (how the server sends dates).
  static final _utcIso = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$');

  /// Server bookkeeping timestamps stay in UTC exactly as sent.
  static const _serverTimeKeys = {'updatedAt', 'deletedAt', kServerUpdatedAt};

  /// Recursively: local date strings → UTC, whole doubles → ints (so 900 and
  /// 900.0 compare equal), DateTime → UTC ISO.
  static dynamic _outgoing(dynamic v) {
    if (v is DateTime) return v.toUtc().toIso8601String();
    if (v is String && _localIso.hasMatch(v)) return DateTime.parse(v).toUtc().toIso8601String();
    if (v is double && v.isFinite && v == v.truncateToDouble()) return v.toInt();
    if (v is Map) return {for (final e in v.entries) '${e.key}': _outgoing(e.value)};
    if (v is List) return [for (final x in v) _outgoing(x)];
    return v;
  }

  /// Recursively: server UTC date strings → local (the app's storage format).
  static dynamic _incoming(dynamic v, [String? key]) {
    if (v is String && key != null && !_serverTimeKeys.contains(key) && _utcIso.hasMatch(v)) {
      return DateTime.parse(v).toLocal().toIso8601String();
    }
    if (v is String && key == null && _utcIso.hasMatch(v)) {
      return DateTime.parse(v).toLocal().toIso8601String();
    }
    if (v is Map) return {for (final e in v.entries) '${e.key}': _incoming(e.value, '${e.key}')};
    if (v is List) return [for (final x in v) _incoming(x)];
    return v;
  }

  /// Strips local-only fields and converts values to the wire format.
  static Map<String, dynamic> toWire(Map<dynamic, dynamic> record) {
    final out = <String, dynamic>{};
    record.forEach((k, v) {
      if (!_localOnlyFields.contains(k)) out['$k'] = v;
    });
    return Map<String, dynamic>.from(_outgoing(out) as Map);
  }

  Future<void> enqueueCreate(String collection, String id, Map<dynamic, dynamic> record, {String? shopId}) =>
      _add({
        'collection': collection,
        'op': 'create',
        'id': id,
        'shopId': ?shopId,
        'doc': toWire(record),
      });

  /// Queues only the changed fields. Folds into a still-pending create/update.
  Future<void> enqueueUpdate(
    String collection,
    String id,
    Map<dynamic, dynamic> before,
    Map<dynamic, dynamic> after,
  ) async {
    final a = toWire(before), b = toWire(after);
    final patch = <String, dynamic>{
      for (final k in b.keys)
        if (jsonEncode(a[k]) != jsonEncode(b[k])) k: b[k],
    };
    if (patch.isEmpty) return;

    final create = _findPending(collection, id, 'create');
    if (create != null) {
      final op = create.$2;
      await _outbox.put(create.$1, {...op, 'doc': {...(op['doc'] as Map), ...patch}});
      return;
    }
    final update = _findPending(collection, id, 'update');
    if (update != null) {
      final op = update.$2;
      await _outbox.put(update.$1, {...op, 'patch': {...(op['patch'] as Map), ...patch}});
      onEnqueue?.call();
      return;
    }
    await _add({
      'collection': collection,
      'op': 'update',
      'id': id,
      if (before[kServerUpdatedAt] != null) 'baseUpdatedAt': before[kServerUpdatedAt],
      'patch': patch,
    });
  }

  /// A record that never reached the server just disappears from the outbox.
  Future<void> enqueueDelete(String collection, String id) async {
    final mine = _outbox.keys.where((k) {
      final o = _outbox.get(k)!;
      return o['collection'] == collection && o['id'] == id;
    }).toList();
    final neverSynced = mine.any((k) => _outbox.get(k)!['op'] == 'create');
    await _outbox.deleteAll(mine);
    if (neverSynced) return;
    await _add({'collection': collection, 'op': 'delete', 'id': id});
  }

  /// Stock change as a delta so devices never overwrite each other's counts.
  Future<void> enqueueAdjust(String collection, String id, num delta) async {
    final create = _findPending(collection, id, 'create');
    if (create != null) {
      final op = create.$2;
      final doc = Map<String, dynamic>.from(op['doc'] as Map);
      doc['quantity'] = ((doc['quantity'] as num?) ?? 0) + delta;
      await _outbox.put(create.$1, {...op, 'doc': doc});
      return;
    }
    final adjust = _findPending(collection, id, 'adjust');
    if (adjust != null) {
      final op = adjust.$2;
      await _outbox.put(adjust.$1, {...op, 'delta': (op['delta'] as num) + delta});
      onEnqueue?.call();
      return;
    }
    await _add({'collection': collection, 'op': 'adjust', 'id': id, 'delta': delta});
  }

  // ── Applying server data ──────────────────────────────────────────────────

  /// Converts a server document into the local record shape.
  static Map<String, dynamic> fromServer(Map<String, dynamic> doc) => {
        ...Map<String, dynamic>.from(_incoming(doc) as Map),
        'id': doc['_id'],
        kServerUpdatedAt: doc['updatedAt'],
      };

  /// Writes a server doc locally, keeping local-only fields (e.g. menu images).
  Future<void> putServerDoc(String collection, Map<String, dynamic> doc, {Box<Map>? into}) async {
    final target = into ?? box(collection);
    final id = doc['_id'] as String;
    if (doc['deletedAt'] != null) {
      await target.delete(id);
      return;
    }
    final existing = box(collection).get(id);
    final record = fromServer(doc);
    if (existing != null) {
      for (final f in const ['imageBytes', 'imageBase64']) {
        if (existing[f] != null) record[f] = existing[f];
      }
    }
    await target.put(id, record);
  }

  /// Records the server's updatedAt after a successful push.
  Future<void> stampServerUpdatedAt(String collection, String id, String updatedAt) async {
    final existing = box(collection).get(id);
    if (existing != null) await box(collection).put(id, {...existing, kServerUpdatedAt: updatedAt});
  }

  // ── Ownership / wipe ──────────────────────────────────────────────────────

  /// Wipes all synced data, the outbox and the cursor (not device id).
  Future<void> wipe() async {
    for (final b in _boxes.values) {
      await b.clear();
    }
    await _outbox.clear();
    await _failed.clear();
    for (final k in const ['since', 'afterId', 'scope', 'owner', 'deviceCode', 'activeShopId', 'lastSyncAt']) {
      await _meta.delete(k);
    }
  }

  /// Makes sure local data belongs to [owner] (tenant:user); wipes otherwise.
  Future<void> claimFor(String owner) async {
    if (_meta.get('owner') != owner) {
      await wipe();
      await _meta.put('owner', owner);
    }
  }
}
