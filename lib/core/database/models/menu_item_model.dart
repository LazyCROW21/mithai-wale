import 'package:flutter/foundation.dart';

@immutable
class MenuItem {
  const MenuItem({
    required this.id,
    required this.title,
    this.description,
    this.categoryId,
    required this.price,
    required this.unit,
    this.isAvailable = true,
    required this.createdAt,
  });

  factory MenuItem.fromMap(Map<dynamic, dynamic> map) {
    return MenuItem(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      categoryId: map['categoryId'] as int?,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String,
      isAvailable: map['isAvailable'] as bool? ?? true,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as DateTime? ?? DateTime.now()),
    );
  }

  final int id;
  final String title;
  final String? description;
  final int? categoryId;
  final double price;
  final String unit;
  final bool isAvailable;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'price': price,
      'unit': unit,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MenuItem copyWith({
    int? id,
    String? title,
    Object? description = _undefined,
    Object? categoryId = _undefined,
    double? price,
    String? unit,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description == _undefined ? this.description : description as String?,
      categoryId: categoryId == _undefined ? this.categoryId : categoryId as int?,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          categoryId == other.categoryId &&
          price == other.price &&
          unit == other.unit &&
          isAvailable == other.isAvailable &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        categoryId,
        price,
        unit,
        isAvailable,
        createdAt,
      );
}

const Object _undefined = Object();
