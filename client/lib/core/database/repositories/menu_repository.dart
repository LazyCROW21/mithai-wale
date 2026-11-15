import 'dart:typed_data';

import '../models/menu_item_model.dart';

abstract interface class IMenuRepository {
  Future<List<MenuItem>> getAll();
  Future<List<MenuItem>> getByCategory(String categoryId);
  Future<MenuItem?> getById(String id);
  Future<String> add({
    required String title,
    String? description,
    String? categoryId,
    required double price,
    required String unit,
    bool isAvailable = true,
    Uint8List? imageBytes,
  });
  Future<bool> update(MenuItem item);
  Future<int> delete(String id);
  Stream<List<MenuItem>> watchAll();
}
