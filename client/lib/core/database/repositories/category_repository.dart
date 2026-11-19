import '../models/category_model.dart';

abstract interface class ICategoryRepository {
  Future<List<Category>> getAll();
  Future<Category?> getById(String id);
  Future<String> add({required String name, String? emoji});
  Future<bool> update(Category category);
  Future<int> delete(String id);
  Stream<List<Category>> watchAll();
}
