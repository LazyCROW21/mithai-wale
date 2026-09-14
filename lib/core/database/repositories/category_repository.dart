import '../app_database.dart';

abstract interface class ICategoryRepository {
  Future<List<Category>> getAll();
  Future<Category?> getById(int id);
  Future<int> add({required String name, String? emoji});
  Future<bool> update(Category category);
  Future<int> delete(int id);
  Stream<List<Category>> watchAll();
}
