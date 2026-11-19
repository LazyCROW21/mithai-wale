import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../network/api_client.dart';
import 'print_profile.dart';

/// Reads and writes print setups (page size, printing area, letterhead).
abstract interface class IPrintProfileRepository {
  /// Loads the setups from the server and caches them for offline printing.
  ///
  /// When the server can't be reached the cached copy is returned, unless
  /// [requireFresh] is set (editing must start from the current server state).
  Future<PrintProfileSet> load({bool requireFresh = false});

  /// Saves the franchise default; `null` removes it.
  Future<void> saveFranchise(PrintProfile? profile);

  /// Saves a shop's own setup; `null` makes it use the franchise default again.
  Future<void> saveShop(String shopId, PrintProfile? profile);
}

/// Server-backed implementation with a Hive cache.
class ApiPrintProfileRepository implements IPrintProfileRepository {
  ApiPrintProfileRepository(this._api, this._cacheKey);

  final ApiClient _api;

  /// Identifies whose setups are cached (the signed-in tenant/user).
  final String? Function() _cacheKey;

  static const _boxName = 'print_profiles';

  Future<Box<String>> get _box async =>
      Hive.isBoxOpen(_boxName) ? Hive.box<String>(_boxName) : Hive.openBox<String>(_boxName);

  @override
  Future<PrintProfileSet> load({bool requireFresh = false}) async {
    final key = _cacheKey();
    final box = await _box;
    try {
      final j = await _api.get('/shops/print-profiles') as Map<String, dynamic>;
      if (key != null) await box.put(key, jsonEncode(j));
      return PrintProfileSet.fromJson(j);
    } on ApiException {
      if (requireFresh) rethrow;
      final cached = key == null ? null : box.get(key);
      if (cached == null) return const PrintProfileSet();
      return PrintProfileSet.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    }
  }

  @override
  Future<void> saveFranchise(PrintProfile? profile) => _save('/shops/print-profile', profile);

  @override
  Future<void> saveShop(String shopId, PrintProfile? profile) =>
      _save('/shops/$shopId/print-profile', profile);

  Future<void> _save(String path, PrintProfile? profile) async {
    if (profile == null) {
      await _api.delete(path);
    } else {
      await _api.put(path, body: profile.toJson());
    }
    await load(); // refresh the offline cache
  }
}
