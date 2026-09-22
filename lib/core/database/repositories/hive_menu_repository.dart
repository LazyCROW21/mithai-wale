import 'package:hive/hive.dart';

import '../models/menu_item_model.dart';
import 'menu_repository.dart';

class HiveMenuRepository implements IMenuRepository {
  HiveMenuRepository(this._box);

  final Box<Map> _box;

  @override
  Future<List<MenuItem>> getAll() async {
    return _box.values.map((map) => MenuItem.fromMap(map)).toList();
  }

  @override
  Future<List<MenuItem>> getByCategory(int categoryId) async {
    final all = await getAll();
    return all.where((item) => item.categoryId == categoryId).toList();
  }

  @override
  Future<MenuItem?> getById(int id) async {
    final map = _box.get(id);
    if (map == null) return null;
    return MenuItem.fromMap(map);
  }

  @override
  Future<int> add({
    required String title,
    String? description,
    int? categoryId,
    required double price,
    required String unit,
    bool isAvailable = true,
  }) async {
    final nextId = _nextId();
    final item = MenuItem(
      id: nextId,
      title: title,
      description: description,
      categoryId: categoryId,
      price: price,
      unit: unit,
      isAvailable: isAvailable,
      createdAt: DateTime.now(),
    );
    await _box.put(nextId, item.toMap());
    return nextId;
  }

  @override
  Future<bool> update(MenuItem item) async {
    if (!_box.containsKey(item.id)) return false;
    await _box.put(item.id, item.toMap());
    return true;
  }

  @override
  Future<int> delete(int id) async {
    if (!_box.containsKey(id)) return 0;
    await _box.delete(id);
    return 1;
  }

  @override
  Stream<List<MenuItem>> watchAll() async* {
    yield await getAll();
    yield* _box.watch().asyncMap((_) => getAll());
  }

  int _nextId() {
    if (_box.isEmpty) return 1;
    final keys = _box.keys.whereType<int>();
    if (keys.isEmpty) return 1;
    return keys.reduce((max, e) => e > max ? e : max) + 1;
  }
}
