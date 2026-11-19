import 'package:flutter/foundation.dart';

import '../../sync/ids.dart';
import '../../sync/sync_store.dart';

@immutable
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.shopId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.lowStockThreshold,
    required this.createdAt,
  });

  final String id;
  final String shopId;
  final String name;
  final String unit;
  final num quantity;
  final num lowStockThreshold;
  final DateTime createdAt;

  bool get isLow => quantity <= lowStockThreshold;

  factory InventoryItem.fromMap(Map<dynamic, dynamic> m) => InventoryItem(
        id: m['id'] as String,
        shopId: m['shopId'] as String? ?? '',
        name: m['name'] as String,
        unit: m['unit'] as String,
        quantity: m['quantity'] as num? ?? 0,
        lowStockThreshold: m['lowStockThreshold'] as num? ?? 0,
        createdAt: DateTime.tryParse('${m['createdAt']}') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'shopId': shopId,
        'name': name,
        'unit': unit,
        'quantity': quantity,
        'lowStockThreshold': lowStockThreshold,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Offline-first inventory. Stock changes are queued as deltas.
class InventoryRepository {
  InventoryRepository(this._store);

  final SyncStore _store;
  static const _c = SyncCollections.inventoryItems;

  List<InventoryItem> getAll({String? shopId}) {
    final list = <InventoryItem>[];
    for (final m in _store.box(_c).values) {
      try {
        final item = InventoryItem.fromMap(m);
        if (shopId == null || item.shopId == shopId) list.add(item);
      } catch (_) {}
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Stream<List<InventoryItem>> watch({String? shopId}) async* {
    yield getAll(shopId: shopId);
    yield* _store.box(_c).watch().map((_) => getAll(shopId: shopId));
  }

  Future<void> add({
    required String shopId,
    required String name,
    required String unit,
    required num quantity,
    required num lowStockThreshold,
  }) async {
    final item = InventoryItem(
      id: uuidV4(),
      shopId: shopId,
      name: name,
      unit: unit,
      quantity: quantity,
      lowStockThreshold: lowStockThreshold,
      createdAt: DateTime.now(),
    );
    final record = item.toMap();
    await _store.box(_c).put(item.id, record);
    await _store.enqueueCreate(_c, item.id, record, shopId: shopId);
  }

  /// Applies [delta] locally right away; the server re-checks stock on push.
  Future<bool> adjust(String id, num delta) async {
    final m = _store.box(_c).get(id);
    if (m == null) return false;
    final next = ((m['quantity'] as num?) ?? 0) + delta;
    if (next < 0) return false;
    await _store.box(_c).put(id, {...m, 'quantity': next});
    await _store.enqueueAdjust(_c, id, delta);
    return true;
  }
}
