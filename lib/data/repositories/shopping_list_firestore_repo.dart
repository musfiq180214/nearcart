import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_list_model.dart';

class ShoppingListFirestoreRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('shopping_lists');

  Future<void> createList(ShoppingListModel list) async {
    await _col.doc(list.uuid).set(list.toJson());
  }

  Stream<List<ShoppingListModel>> watchAllLists() {
    return _col.snapshots().map((snap) =>
        snap.docs.map((e) => ShoppingListModel.fromJson(e.data() as Map<String, dynamic>)).toList());
  }

  Stream<List<ShoppingListModel>> watchListsForStore(String storeUuid) {
    return _col
        .where('storeUuid', isEqualTo: storeUuid)
        .snapshots()
        .map((snap) => snap.docs
        .map((e) => ShoppingListModel.fromJson(e.data() as Map<String, dynamic>))
        .toList());
  }

  Future<ShoppingListModel?> getListByUuid(String uuid) async {
    final doc = await _col.doc(uuid).get();
    if (!doc.exists) return null;
    return ShoppingListModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<void> _updateList(ShoppingListModel list) async {
    await _col.doc(list.uuid).update(list.toJson());
  }

  Future<ShoppingListModel> addItemToList(
      ShoppingListModel list, CartItemModel item) async {
    list.items.add(item);
    await _updateList(list);
    return list;
  }

  Future<ShoppingListModel> toggleItemChecked(
      ShoppingListModel list, String itemUuid) async {
    final item = list.items.firstWhere((e) => e.uuid == itemUuid);
    item.isChecked = !item.isChecked;
    await _updateList(list);
    return list;
  }

  Future<ShoppingListModel> removeItemFromList(
      ShoppingListModel list, String itemUuid) async {
    list.items.removeWhere((e) => e.uuid == itemUuid);
    await _updateList(list);
    return list;
  }

  Future<Map<String, dynamic>> getStats() async {
    final snap = await _col.get();
    final lists = snap.docs
        .map((e) => ShoppingListModel.fromJson(e.data() as Map<String, dynamic>))
        .toList();

    final active = lists.where((e) => !e.isCompleted).length;
    final completed = lists.where((e) => e.isCompleted).length;

    return {
      'totalLists': lists.length,
      'activeLists': active,
      'completedLists': completed,
    };
  }

  ShoppingListModel createShoppingList({
    required String uuid,
    required String name,
    required String storeUuid,
    required String storeName,
  }) {
    final now = DateTime.now();

    return ShoppingListModel(
      uuid: uuid,
      name: name,
      storeUuid: storeUuid,
      storeName: storeName,
      createdAt: now,
      updatedAt: now,
      items: [],
    );
  }
}