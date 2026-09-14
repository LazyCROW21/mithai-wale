import 'package:drift/drift.dart';

import '../app_database.dart';
import 'menu_repository.dart';

class DriftMenuRepository implements IMenuRepository {
  const DriftMenuRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<MenuItem>> getAll() => _db.select(_db.menuItemsTable).get();

  @override
  Future<List<MenuItem>> getByCategory(int categoryId) =>
      (_db.select(_db.menuItemsTable)..where((t) => t.categoryId.equals(categoryId))).get();

  @override
  Future<MenuItem?> getById(int id) =>
      (_db.select(_db.menuItemsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  @override
  Future<int> add({
    required String title,
    String? description,
    int? categoryId,
    required double price,
    required String unit,
    bool isAvailable = true,
  }) {
    return _db.into(_db.menuItemsTable).insert(
          MenuItemsTableCompanion.insert(
            title: title,
            description: Value(description),
            categoryId: Value(categoryId),
            price: price,
            unit: unit,
            isAvailable: Value(isAvailable),
          ),
        );
  }

  @override
  Future<bool> update(MenuItem item) => _db.update(_db.menuItemsTable).replace(item);

  @override
  Future<int> delete(int id) =>
      (_db.delete(_db.menuItemsTable)..where((t) => t.id.equals(id))).go();

  @override
  Stream<List<MenuItem>> watchAll() => _db.select(_db.menuItemsTable).watch();
}
