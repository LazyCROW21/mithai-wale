import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mithai_wale/core/database/models/menu_item_model.dart';
import 'package:mithai_wale/core/database/repositories/cart_repository.dart';
import 'package:mithai_wale/core/di/service_locator.dart';
import 'package:mithai_wale/features/cart/cart_providers.dart';
import 'package:mithai_wale/features/cart/models/cart_item_model.dart';
import 'package:mithai_wale/features/menu/widgets/menu_item_card.dart';

class FakeCartRepository implements ICartRepository {
  final Map<int, CartItem> _storage = {};

  @override
  Future<Map<int, CartItem>> getAll() async => Map.from(_storage);

  @override
  Map<int, CartItem> getAllSync() => Map.from(_storage);

  @override
  Future<void> save(CartItem item) async {
    _storage[item.item.id] = item;
  }

  @override
  Future<void> remove(int itemId) async {
    _storage.remove(itemId);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}

void main() {
  group('CartItem Model & Unit Formatting Tests', () {
    final now = DateTime.now();

    final sweetKg = MenuItem(
      id: 1,
      title: 'Kaju Katli',
      price: 900.0,
      unit: 'kg',
      createdAt: now,
    );

    final milkLitre = MenuItem(
      id: 2,
      title: 'Rabdi Milk',
      price: 120.0,
      unit: 'litre',
      createdAt: now,
    );

    final samosaPc = MenuItem(
      id: 3,
      title: 'Samosa',
      price: 20.0,
      unit: 'per piece',
      createdAt: now,
    );

    final namkeenGm = MenuItem(
      id: 4,
      title: 'Bhujia',
      price: 50.0,
      unit: 'gm',
      createdAt: now,
    );

    test('pricePerUnitLabel formats correctly (Rs. 50/kg, Rs. 50/pc, Rs. 50/gm, Rs. 50/litre)', () {
      final cartKg = CartItem(item: sweetKg, quantity: 4.0);
      final cartLitre = CartItem(item: milkLitre, quantity: 2.4);
      final cartPc = CartItem(item: samosaPc, quantity: 2.0);
      final cartGm = CartItem(item: namkeenGm, quantity: 250.0);

      expect(cartKg.pricePerUnitLabel, 'Rs. 900/kg');
      expect(cartLitre.pricePerUnitLabel, 'Rs. 120/litre');
      expect(cartPc.pricePerUnitLabel, 'Rs. 20/pc');
      expect(cartGm.pricePerUnitLabel, 'Rs. 50/gm');
    });

    test('formattedUnits formats according to qty (e.g. 4 kg, 2.4 litre, 2 pcs)', () {
      final cartKg = CartItem(item: sweetKg, quantity: 4.0);
      final cartLitre = CartItem(item: milkLitre, quantity: 2.4);
      final cartPcSingle = CartItem(item: samosaPc, quantity: 1.0);
      final cartPcMulti = CartItem(item: samosaPc, quantity: 2.0);
      final cartGm = CartItem(item: namkeenGm, quantity: 500.0);

      expect(cartKg.formattedUnits, '4 kg');
      expect(cartLitre.formattedUnits, '2.4 litre');
      expect(cartPcSingle.formattedUnits, '1 pc');
      expect(cartPcMulti.formattedUnits, '2 pcs');
      expect(cartGm.formattedUnits, '500 gm');
    });

    test('totalPrice calculates accurately with fractional quantities', () {
      final cartLitre = CartItem(item: milkLitre, quantity: 2.4);
      // 120.0 * 2.4 = 288.0
      expect(cartLitre.totalPrice, closeTo(288.0, 0.001));

      final cartKg = CartItem(item: sweetKg, quantity: 4.0);
      // 900.0 * 4 = 3600.0
      expect(cartKg.totalPrice, 3600.0);
    });

    test('CartItem serializes toMap and deserializes fromMap accurately', () {
      final cartLitre = CartItem(item: milkLitre, quantity: 2.4);
      final map = cartLitre.toMap();
      final restored = CartItem.fromMap(map);

      expect(restored.item.id, cartLitre.item.id);
      expect(restored.item.title, cartLitre.item.title);
      expect(restored.item.price, cartLitre.item.price);
      expect(restored.quantity, 2.4);
      expect(restored.totalPrice, cartLitre.totalPrice);
      expect(restored.formattedUnits, '2.4 litre');
    });
  });

  group('CartViewModel State Management Tests', () {
    final now = DateTime.now();

    final item1 = MenuItem(
      id: 10,
      title: 'Gulab Jamun',
      price: 50.0,
      unit: 'kg',
      createdAt: now,
    );

    final item2 = MenuItem(
      id: 20,
      title: 'Rasgulla',
      price: 40.0,
      unit: 'litre',
      createdAt: now,
    );

    test('Initial cart state is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(cartProvider);
      expect(state.isEmpty, isTrue);
      expect(state.totalUniqueItems, 0);
      expect(state.totalPrice, 0.0);
    });

    test('addItem adds item directly without initial modal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final vm = container.read(cartProvider.notifier);
      vm.addItem(item1);

      final state = container.read(cartProvider);
      expect(state.isEmpty, isFalse);
      expect(state.contains(10), isTrue);
      expect(state.getQuantity(10), 1.0);
      expect(state.totalUniqueItems, 1);
      expect(state.totalPrice, 50.0);
    });

    test('increment and decrement update quantity, removing when reaching 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final vm = container.read(cartProvider.notifier);
      vm.addItem(item1, 1.0);
      vm.increment(item1, 1.0);

      expect(container.read(cartProvider).getQuantity(10), 2.0);
      expect(container.read(cartProvider).totalPrice, 100.0);

      // Decrement by 1 -> qty 1.0
      vm.decrement(10, 1.0);
      expect(container.read(cartProvider).getQuantity(10), 1.0);

      // Decrement by 1 -> qty 0 -> removed from cart
      vm.decrement(10, 1.0);
      expect(container.read(cartProvider).contains(10), isFalse);
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    test('setQuantity allows setting exact decimal quantities e.g. 2.4', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final vm = container.read(cartProvider.notifier);
      vm.setQuantity(item2, 2.4);

      final state = container.read(cartProvider);
      expect(state.getQuantity(20), 2.4);
      expect(state.totalPrice, closeTo(96.0, 0.001));

      // Setting quantity to 0 removes the item
      vm.setQuantity(item2, 0.0);
      expect(container.read(cartProvider).contains(20), isFalse);
    });

    test('Multiple items total calculations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final vm = container.read(cartProvider.notifier);
      vm.setQuantity(item1, 4.0); // 4 * 50 = 200
      vm.setQuantity(item2, 2.4); // 2.4 * 40 = 96

      final state = container.read(cartProvider);
      expect(state.totalUniqueItems, 2);
      expect(state.totalUnitsCount, closeTo(6.4, 0.001));
      expect(state.totalPrice, closeTo(296.0, 0.001));

      vm.clearCart();
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    test('persists items to ICartRepository and restores on new container initialization', () {
      final fakeRepo = FakeCartRepository();
      sl.registerSingleton<ICartRepository>(fakeRepo);
      addTearDown(() {
        if (sl.isRegistered<ICartRepository>()) {
          sl.unregister<ICartRepository>();
        }
      });

      // 1. First app launch: add items to cart
      final container1 = ProviderContainer();
      final vm1 = container1.read(cartProvider.notifier);
      vm1.addItem(item1, 3.0);
      vm1.addItem(item2, 1.5);
      container1.dispose();

      // Check repository directly has saved items
      expect(fakeRepo._storage.containsKey(item1.id), isTrue);
      expect(fakeRepo._storage[item1.id]!.quantity, 3.0);
      expect(fakeRepo._storage.containsKey(item2.id), isTrue);
      expect(fakeRepo._storage[item2.id]!.quantity, 1.5);

      // 2. Simulated app restart / refresh with new container
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final state2 = container2.read(cartProvider);
      expect(state2.totalUniqueItems, 2);
      expect(state2.getQuantity(item1.id), 3.0);
      expect(state2.getQuantity(item2.id), 1.5);
      expect(state2.totalPrice, (3.0 * 50.0) + (1.5 * 40.0));
    });
  });

  group('MenuItemCard Widget Tests', () {
    final testItem = MenuItem(
      id: 99,
      title: 'Motichoor Laddu',
      description: 'Traditional desi ghee laddu',
      price: 50.0,
      unit: 'kg',
      createdAt: DateTime.now(),
    );

    testWidgets('shows price label (Rs. 50/kg) and toggles from Add to Cart to "- {qty} +" control', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 350,
                height: 300,
                child: MenuItemCard(product: testItem),
              ),
            ),
          ),
        ),
      );

      // Verify title, description, and price/unit label
      expect(find.text('Motichoor Laddu'), findsOneWidget);
      expect(find.text('Rs. 50/kg'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsNothing);

      // Tap "Add to Cart"
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // "Add to Cart" should now be replaced by "- {qty} +" layout
      expect(find.text('Add to Cart'), findsNothing);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('1 kg'), findsOneWidget);

      // Tap "+" to increment
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('1.5 kg'), findsOneWidget);

      // Tap "-" to decrement
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.text('1 kg'), findsOneWidget);

      // Tap "-" to decrement -> 0.5 kg
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.text('0.5 kg'), findsOneWidget);

      // Tap "-" once more -> drops to 0 and reverts to Add to Cart
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.remove), findsNothing);
      expect(find.text('Add to Cart'), findsOneWidget);
    });

    testWidgets('Tapping {qty} opens Edit Quantity dialog/modal', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 350,
                height: 300,
                child: MenuItemCard(product: testItem),
              ),
            ),
          ),
        ),
      );

      // Add to cart first
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // Tap on the '1 kg' center quantity target
      await tester.tap(find.text('1 kg'));
      await tester.pumpAndSettle();

      // Verify dialog is opened with quick presets and update button
      expect(find.text('Update Cart'), findsOneWidget);
      expect(find.text('Quick Select'), findsOneWidget);
      expect(find.text('2 kg'), findsWidgets);
    });
  });
}
