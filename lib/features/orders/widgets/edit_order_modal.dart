import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/menu_item_model.dart';
import '../../../core/database/models/order_model.dart';
import '../../../core/database/models/payment_model.dart';
import '../../../core/database/repositories/menu_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/layout/layout_extensions.dart';
import '../../ledger/ledger_providers.dart';
import '../../ledger/widgets/record_payment_dialog.dart';
import '../orders_providers.dart';

/// Opens the edit order experience with Order Details and Payment Details tabs:
/// - On Desktop: Dialog
/// - On Mobile/Tablet: Modal Bottom Sheet
Future<void> showEditOrderModal(BuildContext context, OrderModel order) {
  if (context.isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780, maxHeight: 840),
          child: OrderEditView(order: order),
        ),
      ),
    );
  } else {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        expand: false,
        builder: (ctx, scrollController) => OrderEditView(
          order: order,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class OrderEditView extends ConsumerStatefulWidget {
  const OrderEditView({
    super.key,
    required this.order,
    this.scrollController,
  });

  final OrderModel order;
  final ScrollController? scrollController;

  @override
  ConsumerState<OrderEditView> createState() => _OrderEditViewState();
}

class _OrderEditViewState extends ConsumerState<OrderEditView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _discountController;

  late DateTime _deliveryDate;
  late String _status;
  late List<OrderItemDetail> _items;
  DiscountType? _discountType;
  String? _discountError;

  static const _statusOptions = [
    'Placed',
    'Preparing',
    'Ready',
    'Delivering',
    'Delivered',
    'Completed',
    'Cancelled',
    'Returned',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final o = widget.order;
    _nameController = TextEditingController(text: o.customerName);
    _phoneController = TextEditingController(text: o.customerPhone);
    _discountType = o.discountType;
    _discountController = TextEditingController(
      text: o.discountAmount > 0
          ? (o.discountAmount % 1 == 0
              ? o.discountAmount.toInt().toString()
              : o.discountAmount.toString())
          : '',
    );
    _deliveryDate = o.deliveryDate;
    _status = o.status;
    _items = List<OrderItemDetail>.from(o.items);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.totalPrice);

  double get _discountAmount {
    final parsed = double.tryParse(_discountController.text.trim()) ?? 0.0;
    return parsed < 0 ? 0.0 : parsed;
  }

  double get _calculatedDiscount {
    if (_discountType == null || _discountAmount <= 0) return 0.0;
    if (_discountType == DiscountType.percentage) {
      return (_subtotal * _discountAmount) / 100.0;
    }
    return _discountAmount.clamp(0.0, _subtotal);
  }

  double get _finalTotal {
    final net = _subtotal - _calculatedDiscount;
    return net < 0 ? 0.0 : net;
  }

  bool _validateDiscount() {
    setState(() => _discountError = null);
    if (_discountType == null) {
      return true;
    }
    final text = _discountController.text.trim();
    if (text.isEmpty) {
      setState(() => _discountError = 'Enter discount value or select "None"');
      return false;
    }
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() => _discountError = 'Discount must be greater than 0');
      return false;
    }
    if (_discountType == DiscountType.percentage) {
      if (amount >= 100) {
        setState(() => _discountError = 'Percentage discount must be less than 100%');
        return false;
      }
    } else if (_discountType == DiscountType.flat) {
      if (amount >= _subtotal) {
        setState(() => _discountError =
            'Flat discount must be less than bill total (₹${_subtotal.toStringAsFixed(2)})');
        return false;
      }
    }
    return true;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateOnly(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTimeOnly(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }


  void _incrementItem(int index) {
    final item = _items[index];
    final step = (item.unit.toLowerCase() == 'kg' || item.unit.toLowerCase() == 'litre') ? 0.5 : 1.0;
    setState(() {
      _items[index] = item.copyWith(quantity: item.quantity + step);
    });
  }

  void _decrementItem(int index) {
    final item = _items[index];
    final step = (item.unit.toLowerCase() == 'kg' || item.unit.toLowerCase() == 'litre') ? 0.5 : 1.0;
    final newQty = item.quantity - step;
    setState(() {
      if (newQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = item.copyWith(quantity: newQty);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _showAddItemDialog() async {
    final menuRepo = sl.isRegistered<IMenuRepository>() ? sl<IMenuRepository>() : null;
    if (menuRepo == null) return;

    final allItems = await menuRepo.getAll();
    if (!mounted) return;

    final selected = await showDialog<MenuItem>(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = allItems
                .where((m) => m.title.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return AlertDialog(
              title: const Text('Add Item to Order'),
              content: SizedBox(
                width: 400,
                height: 380,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search sweets or snacks…',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setDialogState(() => query = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No items found'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final m = filtered[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('₹${m.price.toStringAsFixed(2)} / ${m.unit}'),
                                  trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                                  onTap: () => Navigator.of(ctx).pop(m),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        final existingIndex = _items.indexWhere((i) => i.name.toLowerCase() == selected.title.toLowerCase());
        if (existingIndex >= 0) {
          final cur = _items[existingIndex];
          _items[existingIndex] = cur.copyWith(quantity: cur.quantity + 1.0);
        } else {
          _items.add(OrderItemDetail(
            name: selected.title,
            quantity: 1.0,
            unit: selected.unit,
            unitPrice: selected.price,
          ));
        }
      });
    }
  }

  void _saveChanges() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order must contain at least one item.')),
      );
      return;
    }

    if (!_validateDiscount()) {
      return;
    }

    final updated = widget.order.copyWith(
      customerName: _nameController.text.trim().isEmpty ? 'Customer' : _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      items: _items,
      deliveryDate: _deliveryDate,
      status: _status,
      discountType: _discountType,
      discountAmount: _discountType == null ? 0.0 : _discountAmount,
      totalBill: _finalTotal,
    );

    ref.read(ordersViewModelProvider.notifier).updateOrder(updated);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${updated.id} updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Top Modal Header with Order ID & Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: cs.primary, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Management',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.order.id,
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar: Order Details vs Payment Details
            TabBar(
              controller: _tabController,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              indicatorColor: cs.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.receipt_long_outlined, size: 20),
                  text: 'Order Details',
                ),
                Tab(
                  icon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                  text: 'Payment Details',
                ),
              ],
            ),
            const Divider(height: 1),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderDetailsTab(context, theme, cs),
                  _buildPaymentDetailsTab(context, theme, cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Order Details ────────────────────────────────────────────────────
  Widget _buildOrderDetailsTab(BuildContext context, ThemeData theme, ColorScheme cs) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // ── Customer Details ──────────────────────────────────────
              Text(
                'Customer & Status',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Status and Delivery Date in a Row
              Row(
                children: [
                  // Status Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusOptions.contains(_status) ? _status : 'Placed',
                      decoration: const InputDecoration(
                        labelText: 'Order Status',
                        prefixIcon: Icon(Icons.info_outline, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _statusOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Delivery Date Picker
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _deliveryDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _deliveryDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Delivery Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Text(
                          _formatDate(_deliveryDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Items Section ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items in Order (${_items.length})',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                  ),
                  TextButton.icon(
                    onPressed: _showAddItemDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: Text('No items in this order. Tap "+ Add Item"')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final qtyStr = item.quantity % 1 == 0
                              ? item.quantity.toInt().toString()
                              : item.quantity.toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        '₹${item.unitPrice.toStringAsFixed(2)} / ${item.unit}',
                                        style: TextStyle(fontSize: 12, color: cs.outline),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity Stepper
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton.filledTonal(
                                      iconSize: 16,
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.remove),
                                      onPressed: () => _decrementItem(index),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '$qtyStr ${item.unit}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      iconSize: 16,
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.add),
                                      onPressed: () => _incrementItem(index),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    '₹${item.totalPrice.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
                                  onPressed: () => _removeItem(index),
                                  tooltip: 'Remove Item',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),

              // ── Discount Section ───────────────────────────────────────
              Text(
                'Discount & Bill Calculation',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
              ),
              const SizedBox(height: 10),

              // Discount Type Segmented / Choice Chips
              Row(
                children: [
                  const Text('Discount Type: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('None'),
                        selected: _discountType == null,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _discountType = null;
                              _discountController.clear();
                              _discountError = null;
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Percentage (%)'),
                        selected: _discountType == DiscountType.percentage,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _discountType = DiscountType.percentage;
                              _discountError = null;
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Flat (₹)'),
                        selected: _discountType == DiscountType.flat,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _discountType = DiscountType.flat;
                              _discountError = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_discountType != null) ...[
                TextField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: _discountType == DiscountType.percentage
                        ? 'Discount Percentage (0 < % < 100)'
                        : 'Flat Discount Amount in ₹ (0 < ₹ < ${_subtotal.toStringAsFixed(2)})',
                    prefixIcon: Icon(
                      _discountType == DiscountType.percentage ? Icons.percent : Icons.currency_rupee,
                      size: 18,
                    ),
                    errorText: _discountError,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) {
                    setState(() => _discountError = null);
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Bill Breakdown Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: TextStyle(color: cs.onSurfaceVariant)),
                        Text('₹${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (_discountType != null && _calculatedDiscount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _discountType == DiscountType.percentage
                                ? 'Discount ($_discountAmount%)'
                                : 'Discount (Flat)',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '-₹${_calculatedDiscount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${_finalTotal.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom Actions
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  elevation: 1,
                  shadowColor: Colors.black12,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  elevation: 3,
                  shadowColor: Colors.black45,
                ),
                onPressed: _saveChanges,
                icon: const Icon(Icons.check),
                label: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Payment Details (New) ────────────────────────────────────────────
  Widget _buildPaymentDetailsTab(BuildContext context, ThemeData theme, ColorScheme cs) {
    final orderPayments = ref.watch(orderPaymentsProvider(widget.order.id));

    final billTotal = _subtotal;
    final discountedTotal = _finalTotal;
    final creditTotal = orderPayments
        .where((p) => p.isCredit)
        .fold(0.0, (sum, p) => sum + p.amount);
    final debitTotal = orderPayments
        .where((p) => p.isDebit)
        .fold(0.0, (sum, p) => sum + p.amount);

    final netPaid = creditTotal - debitTotal;
    final netPayable = discountedTotal - netPaid;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Top Indicators ──────────────────────────────────────────────────
        Text(
          'Payment Summary Indicators',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
        ),
        const SizedBox(height: 10),

        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 640;
            final indicatorCards = [
              _buildIndicatorCard(
                title: 'Bill Total',
                amount: billTotal,
                subtitle: 'Subtotal',
                color: cs.onSurface,
                icon: Icons.receipt,
                cs: cs,
              ),
              _buildIndicatorCard(
                title: 'Discounted Total',
                amount: discountedTotal,
                subtitle: _calculatedDiscount > 0
                    ? '-₹${_calculatedDiscount.toStringAsFixed(0)} off'
                    : 'No discount',
                color: cs.primary,
                icon: Icons.sell_outlined,
                cs: cs,
              ),
              _buildIndicatorCard(
                title: 'Credit Total',
                amount: creditTotal,
                subtitle: 'Payments Received',
                color: Colors.green,
                icon: Icons.arrow_downward,
                cs: cs,
              ),
              _buildIndicatorCard(
                title: 'Debit Total',
                amount: debitTotal,
                subtitle: 'Refunds Given',
                color: Colors.deepOrange,
                icon: Icons.arrow_upward,
                cs: cs,
              ),
              _buildIndicatorCard(
                title: 'Net Payable',
                amount: netPayable.abs(),
                subtitle: netPayable > 0.009
                    ? 'Balance Due'
                    : (netPayable < -0.009 ? 'Refund Due' : 'Fully Paid ✓'),
                color: netPayable > 0.009
                    ? Colors.amber.shade900
                    : (netPayable < -0.009 ? Colors.deepOrange : Colors.green),
                icon: Icons.account_balance_wallet,
                cs: cs,
                isHighlight: true,
              ),
            ];

            if (isCompact) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: indicatorCards
                      .map((card) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: SizedBox(width: 150, child: card),
                          ))
                      .toList(),
                ),
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: indicatorCards
                  .map((card) => SizedBox(
                        width: (constraints.maxWidth - 40) / 5,
                        child: card,
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),

        // ── Table Header & Action Button ────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Activity Records (${orderPayments.length})',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                ),
                Text(
                  'Chronological payment & refund history for ${widget.order.id}',
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                elevation: 3,
                shadowColor: Colors.black45,
              ),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Record Payment / Refund'),
              onPressed: () {
                showRecordPaymentDialog(
                  context,
                  orderId: widget.order.id,
                  customerName: _nameController.text.trim(),
                  suggestedAmount: netPayable > 0 ? netPayable : null,
                  defaultType: netPayable < -0.009 ? PaymentType.debit : PaymentType.credit,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Records Table ───────────────────────────────────────────────────
        if (orderPayments.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_outlined, size: 48, color: cs.outline),
                const SizedBox(height: 12),
                const Text(
                  'No payments or refunds recorded yet for this order.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "Record Payment / Refund" above to record customer payments or return refunds.',
                  style: TextStyle(fontSize: 12, color: cs.outline),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 680),
                  child: DataTable(
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 58,
                    headingRowColor: WidgetStateProperty.all(
                      cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    ),
                    columns: const [
                      DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Credit / Debit', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Reason / Note', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Reference', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: orderPayments.map((p) {
                      final isCredit = p.isCredit;
                      final typeColor = isCredit ? Colors.green.shade700 : Colors.red.shade700;
                      final sign = isCredit ? '+' : '-';
                      final amountStr = p.amount % 1 == 0
                          ? p.amount.toInt().toString()
                          : p.amount.toStringAsFixed(2);

                      return DataRow(
                        cells: [
                          // Date & Time in different lines
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDateOnly(p.createdAt),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTimeOnly(p.createdAt),
                                    style: TextStyle(fontSize: 11, color: cs.outline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Merged Credit / Debit column: "+ 120" in green or "- 50" in red
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '$sign $amountStr',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: typeColor,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.paymentMode,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: Text(
                                p.note.isNotEmpty ? p.note : '—',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              p.referenceNumber ?? '—',
                              style: TextStyle(fontSize: 11, color: cs.outline),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 18, color: cs.outline),
                              tooltip: 'Delete Entry',
                              onPressed: () {
                                _confirmDeletePayment(context, p);
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _confirmDeletePayment(BuildContext context, PaymentModel p) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment Record?'),
        content: Text(
          'Delete transaction of ₹${p.amount.toStringAsFixed(2)} (${p.typeDisplayName}) for this order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              ref.read(ledgerViewModelProvider.notifier).deletePayment(p.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard({
    required String title,
    required double amount,
    required String subtitle,
    required Color color,
    required IconData icon,
    required ColorScheme cs,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlight
            ? color.withValues(alpha: 0.12)
            : cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight ? color.withValues(alpha: 0.5) : cs.outlineVariant.withValues(alpha: 0.7),
          width: isHighlight ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isHighlight ? 0.08 : 0.04),
            blurRadius: isHighlight ? 6 : 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
