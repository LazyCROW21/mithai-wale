import 'dart:typed_data';

import '../../sync/ids.dart';
import '../../sync/sync_store.dart';
import '../models/menu_item_model.dart';
import 'menu_repository.dart';

/// Offline-first menu items. Images stay on this device (not synced yet).
class HiveMenuRepository implements IMenuRepository {
  HiveMenuRepository(this._store);

  final SyncStore _store;
  static const _c = SyncCollections.menuItems;

  @override
  Future<List<MenuItem>> getAll() async {
    final list = <MenuItem>[];
    for (final map in _store.box(_c).values) {
      try {
        list.add(MenuItem.fromMap(map));
      } catch (_) {}
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<List<MenuItem>> getByCategory(String categoryId) async =>
      (await getAll()).where((item) => item.categoryId == categoryId).toList();

  @override
  Future<MenuItem?> getById(String id) async {
    final map = _store.box(_c).get(id);
    return map == null ? null : MenuItem.fromMap(map);
  }

  @override
  Future<String> add({
    required String title,
    String? description,
    String? categoryId,
    required double price,
    required String unit,
    bool isAvailable = true,
    Uint8List? imageBytes,
  }) async {
    final item = MenuItem(
      id: uuidV4(),
      title: title,
      description: description,
      categoryId: categoryId,
      price: price,
      unit: unit,
      isAvailable: isAvailable,
      imageBytes: imageBytes,
      createdAt: DateTime.now(),
    );
    final record = item.toMap();
    await _store.box(_c).put(item.id, record);
    await _store.enqueueCreate(_c, item.id, record);
    return item.id;
  }

  @override
  Future<bool> update(MenuItem item) async {
    final before = _store.box(_c).get(item.id);
    if (before == null) return false;
    final after = {...before, ...item.toMap()};
    await _store.box(_c).put(item.id, after);
    await _store.enqueueUpdate(_c, item.id, before, after);
    return true;
  }

  @override
  Future<int> delete(String id) async {
    if (!_store.box(_c).containsKey(id)) return 0;
    await _store.box(_c).delete(id);
    await _store.enqueueDelete(_c, id);
    return 1;
  }

  @override
  Stream<List<MenuItem>> watchAll() async* {
    yield await getAll();
    yield* _store.box(_c).watch().asyncMap((_) => getAll());
  }
}
