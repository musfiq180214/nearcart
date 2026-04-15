import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_list_model.dart';

class ShoppingListFirestoreRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('shopping_lists');

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> createList(ShoppingListModel list) async {
    await _col.doc(list.uuid).set(list.toJson());
  }

  Future<void> _updateList(ShoppingListModel list) async {
    await _col.doc(list.uuid).update(list.toJson());
  }

  Future<void> deleteList(String uuid) async {
    await _col.doc(uuid).delete();
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// All lists for the current user
  Stream<List<ShoppingListModel>> watchMyLists(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_mapSnap);
  }

  /// Lists for a specific store, scoped to current user
  Stream<List<ShoppingListModel>> watchListsForStore(
      String storeUuid, String userId) {
    return _col
        .where('storeUuid', isEqualTo: storeUuid)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_mapSnap);
  }

  List<ShoppingListModel> _mapSnap(QuerySnapshot snap) => snap.docs
      .map((d) =>
      ShoppingListModel.fromJson(d.data() as Map<String, dynamic>))
      .toList();

  // ── Reads ─────────────────────────────────────────────────────────────────

  Future<ShoppingListModel?> getListByUuid(String uuid) async {
    final doc = await _col.doc(uuid).get();
    if (!doc.exists) return null;
    return ShoppingListModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // ── Item mutations ────────────────────────────────────────────────────────

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

  // ── Stats (user-scoped) ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStats(String userId) async {
    final snap =
    await _col.where('userId', isEqualTo: userId).get();
    final lists = snap.docs
        .map((d) =>
        ShoppingListModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();

    return {
      'totalLists': lists.length,
      'activeLists': lists.where((e) => !e.isCompleted).length,
      'completedLists': lists.where((e) => e.isCompleted).length,
    };
  }

  // ── Factory ───────────────────────────────────────────────────────────────

  ShoppingListModel createShoppingList({
    required String uuid,
    required String userId,
    required String name,
    required String storeUuid,
    required String storeName,
  }) {
    final now = DateTime.now();
    return ShoppingListModel(
      uuid: uuid,
      userId: userId,
      name: name,
      storeUuid: storeUuid,
      storeName: storeName,
      createdAt: now,
      updatedAt: now,
    );
  }
}