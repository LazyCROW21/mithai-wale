import '../app_database.dart';

abstract interface class IMenuRepository {
  Future<List<MenuItem>> getAll();
  Future<List<MenuItem>> getByCategory(int categoryId);
  Future<MenuItem?> getById(int id);
  Future<int> add({
    required String title,
    String? description,
    int? categoryId,
    required double price,
    required String unit,
    bool isAvailable = true,
  });
  Future<bool> update(MenuItem item);
  Future<int> delete(int id);
  Stream<List<MenuItem>> watchAll();
}
