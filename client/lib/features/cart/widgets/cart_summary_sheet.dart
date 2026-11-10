import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/menu_item_model.dart';
import '../../../core/database/repositories/menu_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/layout/layout_extensions.dart';
import '../../../core/routing/router_key.dart';
import '../../../l10n/l10n.dart';
import '../../shop/shop_providers.dart';
import '../cart_providers.dart';
import '../models/cart_item_model.dart';
import 'checkout_dialog.dart';
import 'edit_quantity_dialog.dart';

class CartSummarySheet extends ConsumerStatefulWidget {
  const CartSummarySheet({super.key});

  static String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final dayName = weekdays[date.weekday - 1];
    final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';

    if (date == today) {
      return 'Today • $dayName, $dateStr';
    } else if (date == tomorrow) {
      return 'Tomorrow • $dayName, $dateStr';
    }
    return '$dayName, $dateStr';
  }

  @override
  ConsumerState<CartSummarySheet> createState() => _CartSummarySheetState();
}

class _CartSummarySheetState extends ConsumerState<CartSummarySheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<int, DateTime> _itemDeliveryDates = {};
  List<MenuItem> _cachedCatalog = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    if (sl.isRegistered<IMenuRepository>()) {
      try {
        final items = await sl<IMenuRepository>().getAll();
        if (mounted) {
          setState(() => _cachedCatalog = items);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cart = ref.watch(cartProvider);
    final vm = ref.read(cartProvider.notifier);
    final isMobile = context.isMobile;

    // Get all catalog products for search
    final shopState = ref.watch(shopViewModelProvider);
    final allCatalog = shopState.items.isNotEmpty ? shopState.items : _cachedCatalog;

    final q = _searchQuery.trim().toLowerCase();
    final searchMatches = q.isEmpty
        ? <MenuItem>[]
        : allCatalog.where((m) {
            return m.title.toLowerCase().contains(q) ||
                (m.description?.toLowerCase().contains(q) ?? false) ||
                m.unit.toLowerCase().contains(q);
          }).toList();

    final content = Column(
      children: [
        // ── Top Header Bar ──────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, isMobile ? 8 : 16, 16, 12),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(isMobile ? Icons.arrow_back : Icons.close),
                tooltip: context.l10n.actionClose,
                onPressed: () => AppNav.pop(),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.shoppingCartTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              if (cart.isNotEmpty)
                Badge(
                  label: Text('${cart.totalUniqueItems}'),
                  backgroundColor: cs.primary,
                ),
              const Spacer(),
              if (cart.isNotEmpty)
                IconButton(
                  tooltip: context.l10n.actionClear,
                  icon: Icon(Icons.delete_sweep_outlined, color: cs.error, size: 22),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(context.l10n.clearCartTitle),
                        content: Text(context.l10n.clearCartConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(context.l10n.actionCancel),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(elevation: 2),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(context.l10n.actionClear),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      vm.clearCart();
                    }
                  },
                ),
            ],
          ),
        ),

        // ── Always-Visible Search Bar & Delivery Date Row ───────────────
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.l10n.searchToAddPlaceholder,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: cs.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),

        // ── Main Scrollable Content: Search Results + Cart Groups ─────────
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: 16,
            ),
            children: [
              // ── Search Results Section (Shown whenever user has typed in search bar) ──
              if (_searchQuery.trim().isNotEmpty) ...[
                if (searchMatches.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 40, color: cs.outline),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.noSearchResults(_searchQuery),
                            style: TextStyle(color: cs.outline, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
                    ),
                    color: cs.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search results header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.format_list_bulleted, size: 18, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.l10n.matchingSweets(searchMatches.length),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),

                        // Search result items (each item has a date selector + Add button, without counting items already added)
                        ...searchMatches.map((item) {
                          final now = DateTime.now();
                          final itemDate = _itemDeliveryDates[item.id] ??
                              DateTime(now.year, now.month, now.day);
                          final unit = CartItem.normalizedUnit(item.unit);
                          final defaultStep = (unit == 'kg' || unit == 'litre') ? 0.5 : 1.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              children: [
                                // Item info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${CartItem.formatNumber(item.price)} / $unit',
                                        style: TextStyle(fontSize: 12, color: cs.outline),
                                      ),
                                    ],
                                  ),
                                ),

                                // Delivery Date chip for this item
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: itemDate,
                                      firstDate: DateTime(2025),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _itemDeliveryDates[item.id] =
                                            DateTime(picked.year, picked.month, picked.day);
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.event, size: 13, color: cs.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${itemDate.day}/${itemDate.month}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Always an Add button (never replaced with counter or disabled)
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    elevation: 2,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: Text(
                                    context.l10n.actionAdd,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    final normalizedDate =
                                        DateTime(itemDate.year, itemDate.month, itemDate.day);
                                    vm.addItem(item, defaultStep, normalizedDate);

                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context.l10n.itemAddedSnackbar(
                                            item.title,
                                            CartSummarySheet._formatGroupDate(normalizedDate),
                                          ),
                                        ),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],

              // ── Cart Items Section ─────────────────────────────────────
              if (cart.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: cs.outline),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.cartEmpty,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.cartEmptyPrompt,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.outline, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Info Banner
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_available_outlined, size: 20, color: cs.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Items are formed by delivery date then by title. You can assign different delivery dates to any item.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Flat Items list formed by Date then by Title (Color-coded by date)
                ...() {
                  final uniqueDates = cart.sortedItems
                      .map((ci) => DateTime(ci.deliveryDate.year, ci.deliveryDate.month, ci.deliveryDate.day))
                      .toSet()
                      .toList()
                    ..sort();

                  return cart.sortedItems.map((cartItem) {
                    final item = cartItem.item;
                    final normalizedUnit = CartItem.normalizedUnit(item.unit);
                    final step = (normalizedUnit == 'kg' || normalizedUnit == 'litre') ? 0.5 : 1.0;
                    final dateColor = CartItem.getDeliveryDateColor(cartItem.deliveryDate, cs, uniqueDates);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: cs.surface,
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: dateColor, width: 2.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top row: Delivery date badge + Change Date button
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: dateColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: dateColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: 14, color: dateColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        CartSummarySheet._formatGroupDate(cartItem.deliveryDate),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: dateColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    visualDensity: VisualDensity.compact,
                                    elevation: 1,
                                    side: BorderSide(color: dateColor.withValues(alpha: 0.5)),
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: cartItem.deliveryDate,
                                      firstDate: DateTime(2025),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      vm.updateItemDeliveryDate(cartItem, picked);
                                    }
                                  },
                                  icon: Icon(Icons.edit_calendar, size: 14, color: dateColor),
                                  label: Text(
                                    context.l10n.changeDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: dateColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Main item details row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Rates
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cartItem.summarySubtitle,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: cs.outline,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '₹${CartItem.formatNumber(cartItem.totalPrice)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: dateColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Stepper Controls
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.filledTonal(
                                    iconSize: 18,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => vm.decrement(cartItem.cartKey, step),
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => showEditQuantityDialog(
                                      context,
                                      item: item,
                                      currentQuantity: cartItem.quantity,
                                      cartItem: cartItem,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        CartItem.formatNumber(cartItem.quantity),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    iconSize: 18,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.add),
                                    onPressed: () => vm.increment(cartItem, step),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                                    tooltip: context.l10n.actionDelete,
                                    onPressed: () => vm.removeItem(cartItem.cartKey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                });
              }(),
              ],
            ],
          ),
        ),

        // ── Bottom Checkout Bar ──────────────────────────────────────────
        if (cart.isNotEmpty)
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            decoration: BoxDecoration(
              color: cs.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.grandTotal,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: cs.outline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            context.l10n.itemCount(cart.totalUniqueItems),
                            style: TextStyle(fontSize: 12, color: cs.outline),
                          ),
                        ],
                      ),
                      Text(
                        '₹${CartItem.formatNumber(cart.totalPrice)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        elevation: 3,
                        shadowColor: Colors.black38,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => showCheckoutDialog(context),
                      icon: const Icon(Icons.check_circle_outline, size: 22),
                      label: Text(
                        context.l10n.proceedToCheckout,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    // If mobile: full screen Scaffold. If desktop/tablet: spacious wide container.
    if (isMobile) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(child: content),
      );
    } else {
      return Container(
        constraints: const BoxConstraints(maxWidth: 880),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: content,
      );
    }
  }
}
