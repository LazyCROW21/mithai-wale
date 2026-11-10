import 'dart:convert';
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
    this.imageBytes,
    required this.createdAt,
  });

  factory MenuItem.fromMap(Map<dynamic, dynamic> map) {
    Uint8List? parseBytes(dynamic val) {
      if (val == null) return null;
      if (val is Uint8List) return val;
      if (val is List) return Uint8List.fromList(List<int>.from(val));
      if (val is String && val.isNotEmpty) {
        try {
          return base64Decode(val);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return MenuItem(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      categoryId: map['categoryId'] as int?,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String,
      isAvailable: map['isAvailable'] as bool? ?? true,
      imageBytes: parseBytes(map['imageBytes'] ?? map['imageBase64']),
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
  final Uint8List? imageBytes;
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
      'imageBytes': imageBytes,
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
    Object? imageBytes = _undefined,
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
      imageBytes: imageBytes == _undefined ? this.imageBytes : imageBytes as Uint8List?,
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
          listEquals(imageBytes, other.imageBytes) &&
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
        imageBytes == null ? 0 : Object.hashAll(imageBytes!),
        createdAt,
      );
}

const Object _undefined = Object();
