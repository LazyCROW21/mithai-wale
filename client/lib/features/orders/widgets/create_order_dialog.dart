import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_notifier.dart';
import '../../../core/database/models/menu_item_model.dart';
import '../../../core/database/models/order_model.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/layout/layout_extensions.dart';
import '../../../core/state/shop_filter.dart';
import '../../../core/sync/ids.dart';
import '../../../core/sync/sync_store.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../orders_providers.dart';
import 'menu_item_search_field.dart';
import 'order_lines_editor.dart';

/// Counter-side order entry. Search an item in the dropdown to add it as a
/// row for the default delivery date (today unless changed); the same item
/// can be added any number of times, and each row's date and quantity are
/// edited inline. Rows are sorted
/// by date then name, and possible duplicates are flagged with a merge button.
///
/// No cart — the selection lives only in this dialog.
///
/// The franchise admin must choose the shop (pre-filled from the global shop
/// filter); store-scoped users always bill to their own shop.
///
/// Opened through the `/orders/new/dialog` route.
/// Size: mobile 100%, tablet 90%, desktop 85% of the viewport.
class CreateOrderDialog extends StatelessWidget {
  const CreateOrderDialog({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return const Dialog.fullscreen(child: _CreateOrderForm());
    }
    final fraction = context.isTablet ? 0.9 : 0.85;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: context.screenWidth * fraction,
        height: context.screenHeight * fraction,
        child: const _CreateOrderForm(),
      ),
    );
  }
}

class _CreateOrderForm extends ConsumerStatefulWidget {
  const _CreateOrderForm();

  @override
  ConsumerState<_CreateOrderForm> createState() => _CreateOrderFormState();
}

class _CreateOrderFormState extends ConsumerState<_CreateOrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _discount = TextEditingController();

  /// Order rows, kept sorted by delivery day then item name. The same item
  /// may appear more than once (see [OrderLinesEditor] for duplicates).
  List<OrderItemDetail> _lines = [];

  String? _shopId;

  /// Default delivery day for newly added rows; each row's day can still be
  /// changed afterwards with its own date button.
  DateTime _defaultDate = dayOf(DateTime.now());
  DiscountType? _discountType;
  bool _submitting = false;
  String? _itemsError;

  @override
  void initState() {
    super.initState();
    _shopId = ref.read(defaultShopIdProvider);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _discount.dispose();
    super.dispose();
  }

  double get _subtotal => _lines.fold(0.0, (sum, l) => sum + l.totalPrice);

  double get _discountValue => double.tryParse(_discount.text.trim()) ?? 0.0;

  double get _discountRupees {
    if (_discountType == null || _discountValue <= 0) return 0.0;
    if (_discountType == DiscountType.percentage) return _subtotal * _discountValue / 100.0;
    return _discountValue.clamp(0.0, _subtotal);
  }

  double get _total => (_subtotal - _discountRupees).clamp(0.0, double.infinity);

  /// Adds [item] as a new row for the default date (never merged).
  void _addItem(MenuItem item) {
    setState(() {
      _lines = OrderModel.addLine(
        _lines,
        OrderItemDetail(
          name: item.title,
          quantity: quantityStepFor(item.unit),
          unit: item.unit,
          unitPrice: item.price,
          deliveryDate: _defaultDate,
        ),
      );
      _itemsError = null;
    });
  }

  void _setLines(List<OrderItemDetail> lines) => setState(() => _lines = lines);

  Future<void> _pickDefaultDate() async {
    final picked = await pickDeliveryDay(context, _defaultDate);
    if (picked != null) setState(() => _defaultDate = picked);
  }

  String? _validateDiscount(String? v) {
    if (_discountType == null) return null;
    final n = double.tryParse((v ?? '').trim());
    if (n == null || n <= 0) return context.l10n.orderDiscountInvalid;
    if (_discountType == DiscountType.percentage && n >= 100) return context.l10n.orderDiscountInvalid;
    if (_discountType == DiscountType.flat && n >= _subtotal) return context.l10n.orderDiscountInvalid;
    return null;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final formOk = _formKey.currentState!.validate();
    if (_lines.isEmpty) setState(() => _itemsError = l10n.orderAddItemsFirst);
    if (!formOk || _lines.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final identity = sl.isRegistered<SyncStore>()
          ? await sl<SyncStore>().nextOrderIdentity()
          : (id: '#X-${randomId(8).toUpperCase()}', token: null, tokenDate: null);

      final order = OrderModel(
        id: identity.id,
        token: identity.token,
        shopId: _shopId,
        customerName: _name.text.trim().isEmpty ? l10n.orderWalkInCustomer : _name.text.trim(),
        customerPhone: _phone.text.trim(),
        items: _lines,
        orderDate: DateTime.now(),
        totalBill: _total,
        status: OrderStatus.placed,
        discountType: _discountType,
        discountAmount: _discountType == null ? 0.0 : _discountValue,
      );

      await ref.read(ordersViewModelProvider.notifier).addOrder(order);
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(order);
      if (order.token != null) {
        messenger.showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.orderPlacedWithToken(order.token!, formatNumber(order.totalBill))),
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  /// Default delivery date for new rows.
  Widget _dateField(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: _pickDefaultDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.orderDeliveryDate,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: const OutlineInputBorder(),
        ),
        child: Text(formatDeliveryDay(context, _defaultDate), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  /// Search dropdown + the default date new rows get, then the rows.
  List<Widget> _itemsSection(BuildContext context, {required bool sideBySide}) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final search = MenuItemSearchField(onPicked: _addItem);
    return [
      if (sideBySide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: search),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _dateField(context)),
          ],
        )
      else ...[
        _dateField(context),
        const SizedBox(height: 12),
        search,
      ],
      Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text(
          l10n.orderDefaultDateHint,
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        '${l10n.orderItemsInOrder} (${_lines.length})',
        style: theme.textTheme.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
      ),
      if (_itemsError != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_itemsError!, style: TextStyle(color: cs.error)),
        ),
      const SizedBox(height: 8),
      OrderLinesEditor(lines: _lines, onChanged: _setLines),
    ];
  }

  List<Widget> _detailsSection(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isAdmin = ref.watch(authProvider.select((a) => a.session?.isFranchiseAdmin ?? false));
    return [
      ShopPickerField(value: _shopId, onChanged: (v) => setState(() => _shopId = v)),
      if (isAdmin) const SizedBox(height: 12),
      TextFormField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: l10n.orderCustomerName,
          hintText: l10n.orderWalkInCustomer,
          prefixIcon: const Icon(Icons.person_outline),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: l10n.orderCustomerPhone,
          prefixIcon: const Icon(Icons.phone_outlined),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      Text(l10n.orderDiscount, style: theme.textTheme.labelLarge),
      const SizedBox(height: 8),
      SegmentedButton<DiscountType?>(
        segments: [
          ButtonSegment(value: null, label: Text(l10n.orderDiscountNone)),
          ButtonSegment(value: DiscountType.percentage, label: Text(l10n.orderDiscountPercent)),
          ButtonSegment(value: DiscountType.flat, label: Text(l10n.orderDiscountFlat)),
        ],
        selected: {_discountType},
        onSelectionChanged: (s) => setState(() {
          _discountType = s.first;
          if (_discountType == null) _discount.clear();
        }),
      ),
      if (_discountType != null) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: _discount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: InputDecoration(
            labelText: l10n.orderDiscount,
            suffixText: _discountType == DiscountType.percentage ? '%' : '₹',
            border: const OutlineInputBorder(),
          ),
          validator: _validateDiscount,
          onChanged: (_) => setState(() {}),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final summary = Material(
      elevation: 8,
      color: cs.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.orderItemsSelected(_lines.length), style: theme.textTheme.bodySmall),
                    if (_discountRupees > 0)
                      Text(
                        '${l10n.subtotal} ₹${formatNumber(_subtotal)} − ₹${formatNumber(_discountRupees)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                      ),
                    Text(
                      '${l10n.total} ₹${formatNumber(_total)}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  elevation: 3,
                  shadowColor: Colors.black38,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(l10n.orderPlace),
              ),
            ],
          ),
        ),
      ),
    );

    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.orderNewTitle),
          actions: [
            IconButton(
              tooltip: l10n.actionClose,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Two panes when there is room: items (main) | customer & discount.
            if (constraints.maxWidth >= 840) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: _itemsSection(context, sideBySide: true),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: 360,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: _detailsSection(context),
                    ),
                  ),
                ],
              );
            }
            // One column: items first, then customer & discount.
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                ..._itemsSection(context, sideBySide: constraints.maxWidth >= 560),
                const SizedBox(height: 20),
                ..._detailsSection(context),
              ],
            );
          },
        ),
        bottomNavigationBar: summary,
      ),
    );
  }
}
