import '../../sync/ids.dart';
import '../../sync/sync_store.dart';
import '../models/category_model.dart';
import 'category_repository.dart';

/// Offline-first categories: writes go to Hive and the sync outbox together.
class HiveCategoryRepository implements ICategoryRepository {
  HiveCategoryRepository(this._store);

  final SyncStore _store;
  static const _c = SyncCollections.categories;

  @override
  Future<List<Category>> getAll() async {
    final list = _store.box(_c).values.map(Category.fromMap).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<Category?> getById(String id) async {
    final map = _store.box(_c).get(id);
    return map == null ? null : Category.fromMap(map);
  }

  @override
  Future<String> add({required String name, String? emoji}) async {
    final category = Category(id: uuidV4(), name: name, emoji: emoji, createdAt: DateTime.now());
    final record = category.toMap();
    await _store.box(_c).put(category.id, record);
    await _store.enqueueCreate(_c, category.id, record);
    return category.id;
  }

  @override
  Future<bool> update(Category category) async {
    final before = _store.box(_c).get(category.id);
    if (before == null) return false;
    final after = {...before, ...category.toMap()};
    await _store.box(_c).put(category.id, after);
    await _store.enqueueUpdate(_c, category.id, before, after);
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
  Stream<List<Category>> watchAll() async* {
    yield await getAll();
    yield* _store.box(_c).watch().asyncMap((_) => getAll());
  }
}
