import 'package:flutter/foundation.dart';

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    this.emoji,
    required this.createdAt,
  });

  factory Category.fromMap(Map<dynamic, dynamic> map) {
    return Category(
      id: map['id'] as int,
      name: map['name'] as String,
      emoji: map['emoji'] as String?,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as DateTime? ?? DateTime.now()),
    );
  }

  final int id;
  final String name;
  final String? emoji;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    Object? emoji = _undefined,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji == _undefined ? this.emoji : emoji as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          emoji == other.emoji &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, name, emoji, createdAt);
}

const Object _undefined = Object();
