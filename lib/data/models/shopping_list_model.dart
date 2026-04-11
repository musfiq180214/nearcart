import 'package:isar/isar.dart';

part 'shopping_list_model.g.dart';

@collection
class ShoppingListModel {
  Id id = Isar.autoIncrement;

  late String uuid;
  late String name;
  late String storeUuid;      // linked store
  late String storeName;      // denormalized for display
  late DateTime createdAt;
  late DateTime updatedAt;
  bool isCompleted = false;
  DateTime? completedAt;
  String? note;

  // Embedded items
  late List<CartItemEmbedded> items;

  @ignore
  int get totalItems => items.length;

  @ignore
  int get checkedItems => items.where((i) => i.isChecked).length;

  @ignore
  double get totalEstimatedCost =>
      items.fold(0, (sum, i) => sum + (i.estimatedPrice ?? 0) * i.quantity);

  @ignore
  double get progress =>
      totalItems == 0 ? 0 : checkedItems / totalItems;
}

@embedded
class CartItemEmbedded {
  late String uuid;
  late String name;
  int quantity = 1;
  String? unit;           // kg, piece, litre, etc.
  double? estimatedPrice;
  bool isChecked = false;
  String? category;       // produce, dairy, meat, etc.
  String? note;
  DateTime? checkedAt;
  String? iconEmoji;
}

/// Factories
ShoppingListModel createShoppingList({
  required String uuid,
  required String name,
  required String storeUuid,
  required String storeName,
  String? note,
  List<CartItemEmbedded>? items,
}) {
  final list = ShoppingListModel()
    ..uuid = uuid
    ..name = name
    ..storeUuid = storeUuid
    ..storeName = storeName
    ..note = note
    ..items = items ?? []
    ..createdAt = DateTime.now()
    ..updatedAt = DateTime.now();
  return list;
}

CartItemEmbedded createCartItem({
  required String uuid,
  required String name,
  int quantity = 1,
  String? unit,
  double? estimatedPrice,
  String? category,
  String? note,
  String? iconEmoji,
}) {
  return CartItemEmbedded()
    ..uuid = uuid
    ..name = name
    ..quantity = quantity
    ..unit = unit
    ..estimatedPrice = estimatedPrice
    ..category = category
    ..note = note
    ..iconEmoji = iconEmoji;
}
