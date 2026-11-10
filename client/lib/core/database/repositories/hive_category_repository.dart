import 'package:hive/hive.dart';

import '../models/category_model.dart';
import 'category_repository.dart';

class HiveCategoryRepository implements ICategoryRepository {
  HiveCategoryRepository(this._box);

  final Box<Map> _box;

  @override
  Future<List<Category>> getAll() async {
    return _box.values.map((map) => Category.fromMap(map)).toList();
  }

  @override
  Future<Category?> getById(int id) async {
    final map = _box.get(id);
    if (map == null) return null;
    return Category.fromMap(map);
  }

  @override
  Future<int> add({required String name, String? emoji}) async {
    final nextId = _nextId();
    final category = Category(
      id: nextId,
      name: name,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
    await _box.put(nextId, category.toMap());
    return nextId;
  }

  @override
  Future<bool> update(Category category) async {
    if (!_box.containsKey(category.id)) return false;
    await _box.put(category.id, category.toMap());
    return true;
  }

  @override
  Future<int> delete(int id) async {
    if (!_box.containsKey(id)) return 0;
    await _box.delete(id);
    return 1;
  }

  @override
  Stream<List<Category>> watchAll() async* {
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
