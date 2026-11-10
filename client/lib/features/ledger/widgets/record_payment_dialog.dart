import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/payment_model.dart';
import '../ledger_providers.dart';

/// Opens the Record Payment / Refund dialog.
Future<PaymentModel?> showRecordPaymentDialog(
  BuildContext context, {
  String? orderId,
  String? customerName,
  double? suggestedAmount,
  PaymentType? defaultType,
}) {
  return showDialog<PaymentModel>(
    context: context,
    builder: (context) => RecordPaymentDialog(
      orderId: orderId,
      customerName: customerName,
      suggestedAmount: suggestedAmount,
      defaultType: defaultType,
    ),
  );
}

class RecordPaymentDialog extends ConsumerStatefulWidget {
  const RecordPaymentDialog({
    super.key,
    this.orderId,
    this.customerName,
    this.suggestedAmount,
    this.defaultType,
  });

  final String? orderId;
  final String? customerName;
  final double? suggestedAmount;
  final PaymentType? defaultType;

  @override
  ConsumerState<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _orderIdController;
  late TextEditingController _customerController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _referenceController;

  late PaymentType _type;
  String _paymentMode = 'Cash';
  bool _isSaving = false;

  static const _modes = ['Cash', 'UPI', 'Card', 'Net Banking', 'Cheque', 'Other'];

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType ?? PaymentType.credit;
    _orderIdController = TextEditingController(text: widget.orderId ?? '');
    _customerController = TextEditingController(text: widget.customerName ?? '');
    _amountController = TextEditingController(
      text: widget.suggestedAmount != null && widget.suggestedAmount! > 0
          ? widget.suggestedAmount!.toStringAsFixed(2)
          : '',
    );
    _noteController = TextEditingController(
      text: _type == PaymentType.credit ? 'Payment received' : 'Refund returned',
    );
    _referenceController = TextEditingController();
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _customerController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payment = PaymentModel(
        id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        orderId: _orderIdController.text.trim(),
        amount: amount,
        type: _type,
        paymentMode: _paymentMode,
        note: _noteController.text.trim().isEmpty
            ? (_type == PaymentType.credit ? 'Payment received' : 'Refund given')
            : _noteController.text.trim(),
        customerName: _customerController.text.trim(),
        referenceNumber: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref.read(ledgerViewModelProvider.notifier).addPayment(payment);

      if (!mounted) return;
      Navigator.of(context).pop(payment);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_type == PaymentType.credit ? "Payment received" : "Refund recorded"} of ₹${amount.toStringAsFixed(2)} for ${payment.orderId}',
          ),
          backgroundColor: _type == PaymentType.credit ? Colors.green.shade800 : Colors.deepOrange.shade800,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isCredit = _type == PaymentType.credit;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isCredit
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.deepOrange.withValues(alpha: 0.15),
                      child: Icon(
                        isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isCredit ? Colors.green : Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCredit ? 'Record Payment' : 'Record Refund',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isCredit ? 'Credit to order balance' : 'Debit refund to customer',
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
                const SizedBox(height: 20),

                // Transaction Type Selector (Credit vs Debit)
                SegmentedButton<PaymentType>(
                  segments: const [
                    ButtonSegment<PaymentType>(
                      value: PaymentType.credit,
                      label: Text('Payment (Credit)'),
                      icon: Icon(Icons.add_circle_outline, color: Colors.green),
                    ),
                    ButtonSegment<PaymentType>(
                      value: PaymentType.debit,
                      label: Text('Refund (Debit)'),
                      icon: Icon(Icons.remove_circle_outline, color: Colors.deepOrange),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (val) {
                    setState(() {
                      _type = val.first;
                      if (_noteController.text == 'Payment received' || _noteController.text == 'Refund returned') {
                        _noteController.text = _type == PaymentType.credit ? 'Payment received' : 'Refund returned';
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Order ID Field
                TextFormField(
                  controller: _orderIdController,
                  decoration: const InputDecoration(
                    labelText: 'Order ID *',
                    hintText: 'e.g. #ORD-12345',
                    prefixIcon: Icon(Icons.tag, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Order ID is required' : null,
                ),
                const SizedBox(height: 12),

                // Customer Name Field
                TextFormField(
                  controller: _customerController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount (₹) *',
                    prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'INR',
                    suffixStyle: TextStyle(color: cs.outline, fontWeight: FontWeight.bold),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Amount is required';
                    final num = double.tryParse(val.trim());
                    if (num == null || num <= 0) return 'Enter a valid amount > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Payment Mode Selector
                DropdownButtonFormField<String>(
                  initialValue: _paymentMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                    prefixIcon: Icon(Icons.payment, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _modes
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMode = val);
                  },
                ),
                const SizedBox(height: 12),

                // Reference / Txn ID
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference / Txn ID (Optional)',
                    hintText: 'e.g. UPI Ref / Card Last 4',
                    prefixIcon: Icon(Icons.confirmation_number_outlined, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Reason / Note
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason / Note',
                    hintText: 'e.g. Advance payment, Full settlement, Return refund',
                    prefixIcon: Icon(Icons.notes_outlined, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isCredit ? Colors.green.shade700 : Colors.deepOrange.shade700,
                        elevation: 3,
                        shadowColor: Colors.black45,
                      ),
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(isCredit ? Icons.check_circle_outline : Icons.replay),
                      label: Text(_isSaving
                          ? 'Recording...'
                          : (isCredit ? 'Record Payment' : 'Record Refund')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
