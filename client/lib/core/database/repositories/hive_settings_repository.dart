import 'package:hive/hive.dart';

import 'settings_repository.dart';

class HiveSettingsRepository implements ISettingsRepository {
  HiveSettingsRepository(this._box);

  final Box<String> _box;

  @override
  Future<String?> get(String key) async {
    return _box.get(key);
  }

  @override
  Future<void> set(String key, String value) async {
    await _box.put(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  @override
  Future<List<SettingEntry>> getAll() async {
    final entries = <SettingEntry>[];
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value != null) {
        entries.add(SettingEntry(key: key.toString(), value: value));
      }
    }
    return entries;
  }

  @override
  Stream<String?> watch(String key) async* {
    yield _box.get(key);
    yield* _box
        .watch(key: key)
        .map((event) => event.value as String?);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
