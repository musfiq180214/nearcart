import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListModel {
  final String uuid;
  final String name;
  final String storeUuid;
  final String storeName;

  final DateTime createdAt;
  final DateTime updatedAt;

  final bool isCompleted;
  final DateTime? completedAt;
  final String? note;

  final List<CartItemModel> items;

  ShoppingListModel({
    required this.uuid,
    required this.name,
    required this.storeUuid,
    required this.storeName,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.completedAt,
    this.note,
    this.items = const [],
  });

  // ── COMPUTED ─────────────────────────────

  int get totalItems => items.length;

  int get checkedItems => items.where((e) => e.isChecked).length;

  double get totalEstimatedCost =>
      items.fold(0, (sum, i) => sum + (i.estimatedPrice ?? 0) * i.quantity);

  double get progress =>
      totalItems == 0 ? 0 : checkedItems / totalItems;

  // ── JSON ────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'storeUuid': storeUuid,
      'storeName': storeName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'note': note,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListModel(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      storeUuid: json['storeUuid'] ?? '',
      storeName: json['storeName'] ?? '',
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? _toDate(json['completedAt'])
          : null,
      note: json['note'],
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CartItemModel.fromJson(e))
          .toList(),
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }
}

class CartItemModel {
  final String uuid;
  final String name;

  final int quantity;
  final String? unit;
  final double? estimatedPrice;

  bool isChecked;
  final String? category;
  final String? note;
  final DateTime? checkedAt;
  final String? iconEmoji;

  CartItemModel({
    required this.uuid,
    required this.name,
    this.quantity = 1,
    this.unit,
    this.estimatedPrice,
    this.isChecked = false,
    this.category,
    this.note,
    this.checkedAt,
    this.iconEmoji,
  });

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'estimatedPrice': estimatedPrice,
      'isChecked': isChecked,
      'category': category,
      'note': note,
      'checkedAt': checkedAt?.toIso8601String(),
      'iconEmoji': iconEmoji,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      unit: json['unit'],
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble(),
      isChecked: json['isChecked'] ?? false,
      category: json['category'],
      note: json['note'],
      checkedAt: json['checkedAt'] != null
          ? ShoppingListModel._toDate(json['checkedAt'])
          : null,
      iconEmoji: json['iconEmoji'],
    );
  }
}
