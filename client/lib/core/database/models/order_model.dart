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

/// Order / delivery-date statuses, in lifecycle order (then the closed ones).
abstract final class OrderStatus {
  static const placed = 'Placed';
  static const preparing = 'Preparing';
  static const ready = 'Ready';
  static const delivering = 'Delivering';
  static const delivered = 'Delivered';
  static const completed = 'Completed';
  static const cancelled = 'Cancelled';
  static const returned = 'Returned';

  static const all = [placed, preparing, ready, delivering, delivered, completed, cancelled, returned];

  /// Cancelled / returned (also legacy "refunded"): no longer counts as business.
  static bool isClosed(String s) {
    final v = s.toLowerCase().trim();
    return v == 'cancelled' || v == 'returned' || v == 'refunded';
  }

  /// Handed over to the customer.
  static bool isFulfilled(String s) {
    final v = s.toLowerCase().trim();
    return v == 'delivered' || v == 'completed';
  }

  static int _rank(String s) {
    final i = all.indexWhere((a) => a.toLowerCase() == s.toLowerCase().trim());
    return i < 0 ? 0 : i;
  }

  /// Overall order status from its delivery-date statuses: the least advanced
  /// active one (an order is only "Delivered" once every date is); when every
  /// date is closed, "Returned" if any was returned, else "Cancelled".
  static String derive(Iterable<String> statuses, {String fallback = placed}) {
    final list = statuses.toList();
    if (list.isEmpty) return fallback;
    final active = list.where((s) => !isClosed(s)).toList();
    if (active.isEmpty) {
      return list.any((s) => s.toLowerCase() == 'returned') ? returned : cancelled;
    }
    active.sort((a, b) => _rank(a).compareTo(_rank(b)));
    return active.first;
  }
}

/// Normalizes [d] to a calendar day (drops the time).
DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Single item line breakdown within an order, with its own delivery date.
///
/// All lines delivering on the same day share one [status] (a "delivery").
@immutable
class OrderItemDetail {
  const OrderItemDetail({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.deliveryDate,
    this.status = OrderStatus.placed,
  });

  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;

  /// The scheduled delivery date for this specific line item.
  final DateTime deliveryDate;

  /// Status of this line's delivery (shared by all lines on the same day).
  final String status;

  /// Lines with the same key are one line (quantities merge).
  String get lineKey =>
      '${name.toLowerCase().trim()}|${unit.toLowerCase().trim()}|$unitPrice|${deliveryDate.year}-${deliveryDate.month}-${deliveryDate.day}';

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'deliveryDate': deliveryDate.toIso8601String(),
        'status': status,
      };

  factory OrderItemDetail.fromMap(
    Map<dynamic, dynamic> map, {
    DateTime? defaultDate,
    String defaultStatus = OrderStatus.placed,
  }) {
    final parsedDate = map['deliveryDate'] != null
        ? DateTime.tryParse(map['deliveryDate'] as String)
        : null;
    return OrderItemDetail(
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'kg',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      deliveryDate: parsedDate ?? defaultDate ?? DateTime.now(),
      // Orders saved before per-date status inherit the order's status.
      status: map['status'] as String? ?? defaultStatus,
    );
  }

  OrderItemDetail copyWith({
    String? name,
    double? quantity,
    String? unit,
    double? unitPrice,
    DateTime? deliveryDate,
    String? status,
  }) {
    return OrderItemDetail(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
    );
  }

  /// Whether this item has the same delivery day as [other] (ignoring time).
  bool isSameDeliveryDay(DateTime other) =>
      deliveryDate.year == other.year &&
      deliveryDate.month == other.month &&
      deliveryDate.day == other.day;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemDetail &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          quantity == other.quantity &&
          unit == other.unit &&
          unitPrice == other.unitPrice &&
          status == other.status &&
          isSameDeliveryDay(other.deliveryDate);

  @override
  int get hashCode => Object.hash(
        name,
        quantity,
        unit,
        unitPrice,
        status,
        deliveryDate.year,
        deliveryDate.month,
        deliveryDate.day,
      );
}

/// Order model containing customer info, order items (each with delivery date), discount, and status.
///
/// Orders do not have an order-level due or delivery date; each item owns its delivery date.
@immutable
class OrderModel {
  const OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.orderDate,
    required this.totalBill,
    required this.status,
    this.discountType,
    this.discountAmount = 0.0,
    this.token,
    this.shopId,
  });

  final String id;

  /// Shop the order belongs to (local metadata; synced separately, never in [toMap]).
  final String? shopId;

  /// Daily token shown to the customer, e.g. "A-12" (device code + daily counter).
  final String? token;
  final String customerName;
  final String customerPhone;
  final List<OrderItemDetail> items;
  final DateTime orderDate;
  final double totalBill;

  /// Overall status, derived from the per-date statuses of [items]
  /// (see [OrderStatus.derive]). Stored so filters and sync keep working.
  final String status;

  /// Status of the delivery on [date]; the overall [status] if nothing is
  /// delivered that day.
  String statusOn(DateTime date) {
    for (final i in items) {
      if (i.isSameDeliveryDay(date)) return i.status;
    }
    return status;
  }

  /// Delivery day → its status, sorted by day.
  Map<DateTime, String> get dateStatuses {
    final map = <DateTime, String>{};
    for (final i in items) {
      map.putIfAbsent(dayOf(i.deliveryDate), () => i.status);
    }
    return Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  /// Copy with every line delivering on [date] set to [newStatus].
  OrderModel withDateStatus(DateTime date, String newStatus) => copyWith(
        items: [for (final i in items) i.isSameDeliveryDay(date) ? i.copyWith(status: newStatus) : i],
      );

  /// Copy with every delivery set to [newStatus].
  OrderModel withAllStatus(String newStatus) =>
      copyWith(items: [for (final i in items) i.copyWith(status: newStatus)]);

  /// Appends [line] as a new row (never merged — the same item may be listed
  /// more than once) and adopts the status already used for that day (one
  /// status per delivery day). Returns the list re-sorted.
  static List<OrderItemDetail> addLine(List<OrderItemDetail> lines, OrderItemDetail line) {
    final day = dayOf(line.deliveryDate);
    final dayStatus = lines.where((l) => l.isSameDeliveryDay(day)).firstOrNull?.status;
    return sortLines([...lines, line.copyWith(deliveryDate: day, status: dayStatus ?? line.status)]);
  }

  /// Merges every row sharing [lineKey] (same item on the same day) into the
  /// first one, summing quantities.
  static List<OrderItemDetail> mergeDuplicates(List<OrderItemDetail> lines, String lineKey) {
    final total = lines.where((l) => l.lineKey == lineKey).fold(0.0, (sum, l) => sum + l.quantity);
    var kept = false;
    return [
      for (final l in lines)
        if (l.lineKey != lineKey)
          l
        else if (!kept && (kept = true))
          l.copyWith(quantity: total),
    ];
  }

  /// Sorted by delivery day, then item name; possible duplicates (same item,
  /// same day) end up next to each other. Stable: equal rows keep their order.
  static List<OrderItemDetail> sortLines(List<OrderItemDetail> lines) {
    final indexed = lines.indexed.toList()
      ..sort((a, b) {
        var c = dayOf(a.$2.deliveryDate).compareTo(dayOf(b.$2.deliveryDate));
        if (c == 0) c = a.$2.name.toLowerCase().compareTo(b.$2.name.toLowerCase());
        if (c == 0) c = a.$2.lineKey.compareTo(b.$2.lineKey);
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  /// Discount type: percentage or flat
  final DiscountType? discountType;

  /// Discount value: percentage (0 < x < 100) or flat amount (0 < x < subtotal)
  final double discountAmount;

  /// Unique sorted list of delivery dates across all items in this order.
  List<DateTime> get deliveryDates {
    final seen = <String>{};
    final dates = <DateTime>[];
    for (final item in items) {
      final key = '${item.deliveryDate.year}-${item.deliveryDate.month.toString().padLeft(2, '0')}-${item.deliveryDate.day.toString().padLeft(2, '0')}';
      if (seen.add(key)) {
        dates.add(DateTime(item.deliveryDate.year, item.deliveryDate.month, item.deliveryDate.day));
      }
    }
    dates.sort();
    return dates;
  }

  /// Earliest delivery date among items in this order, or null if items is empty.
  DateTime? get earliestDeliveryDate => deliveryDates.isNotEmpty ? deliveryDates.first : null;

  /// Latest delivery date among items in this order, or null if items is empty.
  DateTime? get latestDeliveryDate => deliveryDates.isNotEmpty ? deliveryDates.last : null;

  /// Primary delivery date for display or legacy fallback (earliest or orderDate).
  DateTime get primaryDeliveryDate => earliestDeliveryDate ?? orderDate;

  /// Backward-compatible getter for references to order.deliveryDate
  DateTime get deliveryDate => primaryDeliveryDate;

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

  /// Calculated subtotal for items scheduled for delivery on [date] (ignoring time).
  double subtotalForDate(DateTime date) {
    return items
        .where((i) => i.isSameDeliveryDay(date))
        .fold(0.0, (sum, i) => sum + i.totalPrice);
  }

  /// Proportional discount allocated to items scheduled for delivery on [date].
  ///
  /// Business logic formula:
  /// discount of Date1 = total order value of date1 / total order value * discount written
  double discountForDate(DateTime date) {
    if (subtotal <= 0 || calculatedDiscount <= 0) return 0.0;
    final dateSubtotal = subtotalForDate(date);
    if (dateSubtotal <= 0) return 0.0;
    return (dateSubtotal / subtotal) * calculatedDiscount;
  }

  /// Net payable amount for items scheduled for delivery on [date] after proportional discount.
  ///
  /// Calculated as: total order value of date1 - discount of Date1
  double netBillForDate(DateTime date) {
    final dateSubtotal = subtotalForDate(date);
    if (dateSubtotal <= 0) return 0.0;
    final dateDiscount = discountForDate(date);
    final net = dateSubtotal - dateDiscount;
    return net < 0 ? 0.0 : net;
  }

  /// Combines duplicate items if they have identical name, unit, unitPrice AND same delivery date.
  /// Items with different delivery dates remain distinct line items.
  static List<OrderItemDetail> combineItems(List<OrderItemDetail> sourceItems) {
    final map = <String, OrderItemDetail>{};
    for (final item in sourceItems) {
      final key = '${item.name.toLowerCase().trim()}_${item.unit.toLowerCase().trim()}_${item.unitPrice}_${item.deliveryDate.year}-${item.deliveryDate.month.toString().padLeft(2, '0')}-${item.deliveryDate.day.toString().padLeft(2, '0')}';
      if (map.containsKey(key)) {
        final existing = map[key]!;
        map[key] = existing.copyWith(quantity: existing.quantity + item.quantity);
      } else {
        map[key] = item;
      }
    }
    final combined = map.values.toList();
    combined.sort((a, b) {
      final dateComp = a.deliveryDate.compareTo(b.deliveryDate);
      if (dateComp != 0) return dateComp;
      return a.name.compareTo(b.name);
    });
    return combined;
  }

  /// Sorts items by delivery date ascending, then groups by normalized delivery date.
  static Map<DateTime, List<OrderItemDetail>> groupItemsByDeliveryDate(List<OrderItemDetail> items) {
    final sorted = List<OrderItemDetail>.from(items)
      ..sort((a, b) {
        final cmp = a.deliveryDate.compareTo(b.deliveryDate);
        if (cmp != 0) return cmp;
        return a.name.compareTo(b.name);
      });

    final groups = <DateTime, List<OrderItemDetail>>{};
    for (final item in sorted) {
      final dateKey = DateTime(item.deliveryDate.year, item.deliveryDate.month, item.deliveryDate.day);
      groups.putIfAbsent(dateKey, () => []).add(item);
    }
    return groups;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'items': items.map((e) => e.toMap()).toList(),
        'orderDate': orderDate.toIso8601String(),
        'totalBill': finalBill > 0 ? finalBill : totalBill,
        'status': status,
        'discountType': discountType?.name,
        'discountAmount': discountAmount,
        'token': token,
        'tokenDate': token == null
            ? null
            : '${orderDate.year.toString().padLeft(4, '0')}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}',
      };

  factory OrderModel.fromMap(Map<dynamic, dynamic> map) {
    final rawDiscountType = map['discountType'] as String?;
    final discountAmount = (map['discountAmount'] as num?)?.toDouble() ?? 0.0;
    final legacyDeliveryDate = map['deliveryDate'] != null
        ? DateTime.tryParse(map['deliveryDate'] as String)
        : null;

    final items = (map['items'] as List<dynamic>?)
            ?.map((e) => OrderItemDetail.fromMap(
                  e as Map<dynamic, dynamic>,
                  defaultDate: legacyDeliveryDate ?? DateTime.now(),
                  defaultStatus: map['status'] as String? ?? OrderStatus.placed,
                ))
            .toList() ??
        const [];

    final rawBill = (map['totalBill'] as num?)?.toDouble() ?? 0.0;

    return OrderModel(
      id: map['id'] as String? ?? '',
      customerName: map['customerName'] as String? ?? 'Customer',
      customerPhone: map['customerPhone'] as String? ?? '',
      items: items,
      orderDate: map['orderDate'] != null
          ? DateTime.tryParse(map['orderDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      totalBill: rawBill,
      status: map['status'] as String? ?? 'Placed',
      discountType: DiscountType.fromString(rawDiscountType),
      discountAmount: discountAmount,
      token: map['token'] as String?,
      shopId: map['shopId'] as String?,
    );
  }

  OrderModel copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    List<OrderItemDetail>? items,
    DateTime? orderDate,
    double? totalBill,
    String? status,
    Object? discountType = _undefined,
    double? discountAmount,
    DateTime? deliveryDate, // Accepted for backward-compat API calls
    String? token,
    String? shopId,
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
      orderDate: orderDate ?? this.orderDate,
      totalBill: totalBill ?? calcBill,
      // Changing the lines re-derives the overall status from the per-date ones.
      status: status ??
          (items != null
              ? OrderStatus.derive(newItems.map((i) => i.status), fallback: this.status)
              : this.status),
      discountType: newDiscountType,
      discountAmount: newDiscountAmount,
      token: token ?? this.token,
      shopId: shopId ?? this.shopId,
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
          orderDate == other.orderDate &&
          totalBill == other.totalBill &&
          status == other.status &&
          discountType == other.discountType &&
          discountAmount == other.discountAmount &&
          token == other.token;

  @override
  int get hashCode =>
      id.hashCode ^
      customerName.hashCode ^
      customerPhone.hashCode ^
      items.hashCode ^
      orderDate.hashCode ^
      totalBill.hashCode ^
      status.hashCode ^
      discountType.hashCode ^
      discountAmount.hashCode;
}
