import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/routes.dart';
import '../../../core/routing/router_key.dart';
import '../home_providers.dart';

/// Mobile layout for the Home feature.
///
/// Reads [homeViewModelProvider] for all state — no local [StatefulWidget]
/// state for business logic. Local ephemeral state (scroll controllers,
/// animation controllers) may still live in [ConsumerStatefulWidget].
class HomeMobileView extends ConsumerWidget {
  const HomeMobileView({super.key});

  static const _navItems = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Shop'),
    NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
  ];

  static const _navRoutes = [
    AppRoutes.home,
    AppRoutes.shop,
    AppRoutes.orders,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Selective rebuild — only re-renders when selectedNavIndex changes.
    final navIndex = ref.watch(homeViewModelProvider.select((s) => s.selectedNavIndex));
    final vm = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('मिठाई वाले', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: _MobileBody(ref: ref),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: (i) {
          vm.selectNavItem(i);
          AppNav.go(_navRoutes[i]);
        },
        destinations: _navItems,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppNav.showAddToCart(),
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}

class _MobileBody extends ConsumerWidget {
  const _MobileBody({required this.ref});
  // ignore: unused_field
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Search bar ────────────────────────────────────────
        SearchBar(
          hintText: 'Search sweets…',
          leading: const Icon(Icons.search),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
        ),
        const SizedBox(height: 20),

        // ── Categories horizontal scroll ──────────────────────
        Text('Categories', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _CategoryChip(
              label: _categories[i].label,
              emoji: _categories[i].emoji,
              onTap: () => ref.read(homeViewModelProvider.notifier).selectCategory(_categories[i].label),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Featured banner ───────────────────────────────────
        Text('Featured', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const _FeaturedBanner(),
        const SizedBox(height: 24),

        // ── Product grid ──────────────────────────────────────
        Text('Popular Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: _demoProducts.length,
          itemBuilder: (context, i) => _ProductCard(product: _demoProducts[i]),
        ),
      ],
    );
  }
}

// ── Shared sub-widgets & demo data ────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.emoji, this.onTap});
  final String label;
  final String emoji;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Festival Special 🎉', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Get 20% off on all sweets', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onPrimary.withAlpha(200))),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: () {}, child: const Text('Shop Now')),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final _Product product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => AppNav.showProductDetail(product.id),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: cs.surfaceContainerHighest,
                child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 48))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: Theme.of(context).textTheme.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('₹${product.price}/kg', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Category {
  const _Category({required this.label, required this.emoji});
  final String label;
  final String emoji;
}

class _Product {
  const _Product({required this.id, required this.name, required this.price, required this.emoji});
  final String id;
  final String name;
  final int price;
  final String emoji;
}

const _categories = [
  _Category(label: 'Ladoo', emoji: '🟡'),
  _Category(label: 'Barfi', emoji: '🍬'),
  _Category(label: 'Halwa', emoji: '🍮'),
  _Category(label: 'Peda', emoji: '🟤'),
  _Category(label: 'Rasgulla', emoji: '⚪'),
  _Category(label: 'Jalebi', emoji: '🌀'),
];

const _demoProducts = [
  _Product(id: '1', name: 'Motichoor Ladoo', price: 480, emoji: '🟡'),
  _Product(id: '2', name: 'Kaju Barfi', price: 720, emoji: '🍬'),
  _Product(id: '3', name: 'Gajar Halwa', price: 360, emoji: '🍮'),
  _Product(id: '4', name: 'Milk Peda', price: 400, emoji: '🟤'),
  _Product(id: '5', name: 'Rasgulla', price: 320, emoji: '⚪'),
  _Product(id: '6', name: 'Jalebi', price: 280, emoji: '🌀'),
];
