import 'package:flutter/foundation.dart';

const Object _undefined = Object();

/// Discount type supported on orders.
enum DiscountType {
  percentage,
  flat;

  static DiscountType? fromString(String? val) {
    if (val == null) return null;
    final clean = val.toLowerCase().trim();
    if (clean == 'percentage' || clean == '%') return DiscountType.percentage;
    if (clean == 'flat' || clean == 'rs' || clean == 'inr') return DiscountType.flat;
    return null;
  }
}

/// Single item line breakdown within an order.
@immutable
class OrderItemDetail {
  const OrderItemDetail({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
      };

  factory OrderItemDetail.fromMap(Map<dynamic, dynamic> map) {
    return OrderItemDetail(
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'kg',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  OrderItemDetail copyWith({
    String? name,
    double? quantity,
    String? unit,
    double? unitPrice,
  }) {
    return OrderItemDetail(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemDetail &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          quantity == other.quantity &&
          unit == other.unit &&
          unitPrice == other.unitPrice;

  @override
  int get hashCode =>
      name.hashCode ^ quantity.hashCode ^ unit.hashCode ^ unitPrice.hashCode;
}

/// Order model containing customer info, delivery date, items, discount, and status.
@immutable
class OrderModel {
  const OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.deliveryDate,
    required this.orderDate,
    required this.totalBill,
    required this.status,
    this.discountType,
    this.discountAmount = 0.0,
  });

  final String id;
  final String customerName;
  final String customerPhone;
  final List<OrderItemDetail> items;
  final DateTime deliveryDate;
  final DateTime orderDate;
  final double totalBill;

  /// Order status: 'Placed', 'Preparing', 'Ready', 'Delivering', 'Delivered', 'Completed', 'Cancelled'
  final String status;

  /// Discount type: percentage or flat
  final DiscountType? discountType;

  /// Discount value: percentage (0 < x < 100) or flat amount (0 < x < subtotal)
  final double discountAmount;

  /// Calculated subtotal before discount
  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);

  /// Calculated discount in rupees
  double get calculatedDiscount {
    if (discountType == null || discountAmount <= 0) return 0.0;
    if (discountType == DiscountType.percentage) {
      return (subtotal * discountAmount) / 100.0;
    }
    return discountAmount.clamp(0.0, subtotal);
  }

  /// Final payable amount after discount
  double get finalBill {
    final net = subtotal - calculatedDiscount;
    return net < 0 ? 0.0 : net;
  }

  /// Comma-separated list of item names without quantity, e.g. "Motichoor Ladoo, Kaju Barfi"
  String get itemsSummary => items.map((i) => i.name).join(', ');

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'items': items.map((e) => e.toMap()).toList(),
        'deliveryDate': deliveryDate.toIso8601String(),
        'orderDate': orderDate.toIso8601String(),
        'totalBill': finalBill > 0 ? finalBill : totalBill,
        'status': status,
        'discountType': discountType?.name,
        'discountAmount': discountAmount,
      };

  factory OrderModel.fromMap(Map<dynamic, dynamic> map) {
    final rawDiscountType = map['discountType'] as String?;
    final discountAmount = (map['discountAmount'] as num?)?.toDouble() ?? 0.0;
    final items = (map['items'] as List<dynamic>?)
            ?.map((e) => OrderItemDetail.fromMap(e as Map<dynamic, dynamic>))
            .toList() ??
        const [];
    final rawBill = (map['totalBill'] as num?)?.toDouble() ?? 0.0;

    return OrderModel(
      id: map['id'] as String? ?? '',
      customerName: map['customerName'] as String? ?? 'Customer',
      customerPhone: map['customerPhone'] as String? ?? '',
      items: items,
      deliveryDate: map['deliveryDate'] != null
          ? DateTime.tryParse(map['deliveryDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      orderDate: map['orderDate'] != null
          ? DateTime.tryParse(map['orderDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      totalBill: rawBill,
      status: map['status'] as String? ?? 'Placed',
      discountType: DiscountType.fromString(rawDiscountType),
      discountAmount: discountAmount,
    );
  }

  OrderModel copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    List<OrderItemDetail>? items,
    DateTime? deliveryDate,
    DateTime? orderDate,
    double? totalBill,
    String? status,
    Object? discountType = _undefined,
    double? discountAmount,
  }) {
    final newItems = items ?? this.items;
    final newDiscountType = discountType == _undefined
        ? this.discountType
        : discountType as DiscountType?;
    final newDiscountAmount = discountAmount ?? this.discountAmount;

    final sub = newItems.fold(0.0, (sum, i) => sum + i.totalPrice);
    double disc = 0.0;
    if (newDiscountType != null && newDiscountAmount > 0) {
      if (newDiscountType == DiscountType.percentage) {
        disc = (sub * newDiscountAmount) / 100.0;
      } else {
        disc = newDiscountAmount.clamp(0.0, sub);
      }
    }
    final calcBill = (sub - disc).clamp(0.0, double.infinity);

    return OrderModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: newItems,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      orderDate: orderDate ?? this.orderDate,
      totalBill: totalBill ?? calcBill,
      status: status ?? this.status,
      discountType: newDiscountType,
      discountAmount: newDiscountAmount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          customerName == other.customerName &&
          customerPhone == other.customerPhone &&
          listEquals(items, other.items) &&
          deliveryDate == other.deliveryDate &&
          orderDate == other.orderDate &&
          totalBill == other.totalBill &&
          status == other.status &&
          discountType == other.discountType &&
          discountAmount == other.discountAmount;

  @override
  int get hashCode =>
      id.hashCode ^
      customerName.hashCode ^
      customerPhone.hashCode ^
      items.hashCode ^
      deliveryDate.hashCode ^
      orderDate.hashCode ^
      totalBill.hashCode ^
      status.hashCode ^
      discountType.hashCode ^
      discountAmount.hashCode;
}
