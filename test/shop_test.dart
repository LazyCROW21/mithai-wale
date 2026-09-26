import 'package:flutter_test/flutter_test.dart';
import 'package:mithai_wale/core/database/models/category_model.dart';
import 'package:mithai_wale/core/database/models/menu_item_model.dart';
import 'package:mithai_wale/features/shop/shop_state.dart';

void main() {
  group('ShopState Tests', () {
    final cat1 = Category(id: 1, name: 'Ladoo', emoji: '🟡', createdAt: DateTime.now());
    final cat2 = Category(id: 2, name: 'Barfi', emoji: '🍬', createdAt: DateTime.now());

    final item1 = MenuItem(
      id: 1,
      title: 'Motichoor Ladoo',
      categoryId: 1,
      price: 440,
      unit: 'kg',
      isAvailable: true,
      createdAt: DateTime.now(),
    );

    final item2 = MenuItem(
      id: 2,
      title: 'Besan Ladoo',
      categoryId: 1,
      price: 400,
      unit: 'kg',
      isAvailable: false, // Not available
      createdAt: DateTime.now(),
    );

    final item3 = MenuItem(
      id: 3,
      title: 'Kaju Katli',
      categoryId: 2,
      price: 950,
      unit: 'kg',
      isAvailable: true,
      createdAt: DateTime.now(),
    );

    test('availableProducts only returns items where isAvailable is true', () {
      final state = ShopState(
        categories: [cat1, cat2],
        items: [item1, item2, item3],
      );

      final available = state.availableProducts;
      expect(available.length, 2);
      expect(available.any((p) => p.id == 2), isFalse);
      expect(available.map((p) => p.title), containsAll(['Motichoor Ladoo', 'Kaju Katli']));
    });

    test('availableProducts filters by category', () {
      final state = ShopState(
        categories: [cat1, cat2],
        items: [item1, item2, item3],
        selectedCategory: 'Barfi',
      );

      final available = state.availableProducts;
      expect(available.length, 1);
      expect(available.first.title, 'Kaju Katli');
    });

    test('availableProducts filters by search query', () {
      final state = ShopState(
        categories: [cat1, cat2],
        items: [item1, item2, item3],
        searchQuery: 'Motichoor',
      );

      final available = state.availableProducts;
      expect(available.length, 1);
      expect(available.first.title, 'Motichoor Ladoo');
    });
  });
}
