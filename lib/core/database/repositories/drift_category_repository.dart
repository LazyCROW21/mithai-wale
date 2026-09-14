import 'package:drift/drift.dart';

import '../app_database.dart';
import 'category_repository.dart';

class DriftCategoryRepository implements ICategoryRepository {
  const DriftCategoryRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Category>> getAll() => _db.select(_db.categoriesTable).get();

  @override
  Future<Category?> getById(int id) =>
      (_db.select(_db.categoriesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  @override
  Future<int> add({required String name, String? emoji}) {
    return _db.into(_db.categoriesTable).insert(
          CategoriesTableCompanion.insert(
            name: name,
            emoji: Value(emoji),
          ),
        );
  }

  @override
  Future<bool> update(Category category) => _db.update(_db.categoriesTable).replace(category);

  @override
  Future<int> delete(int id) =>
      (_db.delete(_db.categoriesTable)..where((t) => t.id.equals(id))).go();

  @override
  Stream<List<Category>> watchAll() => _db.select(_db.categoriesTable).watch();
}
