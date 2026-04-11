import 'package:isar/isar.dart';
import '../models/shopping_list_model.dart';
import 'isar_service.dart';

class ShoppingListRepository {
  final IsarService _isarService;

  ShoppingListRepository(this._isarService);

  Isar get _db => _isarService.db;

  // ── CREATE ──────────────────────────────────────────────────────────────
  Future<ShoppingListModel> createList(ShoppingListModel list) async {
    await _db.writeTxn(() async {
      await _db.shoppingListModels.put(list);
    });
    return list;
  }

  // ── READ ─────────────────────────────────────────────────────────────────
  Future<List<ShoppingListModel>> getAllLists() async {
    return _db.shoppingListModels
        .where()
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<List<ShoppingListModel>> getListsForStore(String storeUuid) async {
    return _db.shoppingListModels
        .filter()
        .storeUuidEqualTo(storeUuid)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<List<ShoppingListModel>> getActiveLists() async {
    return _db.shoppingListModels
        .filter()
        .isCompletedEqualTo(false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<ShoppingListModel?> getListByUuid(String uuid) async {
    return _db.shoppingListModels.filter().uuidEqualTo(uuid).findFirst();
  }

  Stream<List<ShoppingListModel>> watchAllLists() {
    return _db.shoppingListModels
        .where()
        .watch(fireImmediately: true);
  }

  Stream<List<ShoppingListModel>> watchListsForStore(String storeUuid) {
    return _db.shoppingListModels
        .filter()
        .storeUuidEqualTo(storeUuid)
        .watch(fireImmediately: true);
  }

  // ── UPDATE ───────────────────────────────────────────────────────────────
  Future<ShoppingListModel> updateList(ShoppingListModel list) async {
    list.updatedAt = DateTime.now();
    await _db.writeTxn(() async {
      await _db.shoppingListModels.put(list);
    });
    return list;
  }

  Future<ShoppingListModel> toggleItemChecked(
    ShoppingListModel list,
    String itemUuid,
  ) async {
    final item = list.items.firstWhere((i) => i.uuid == itemUuid);
    item.isChecked = !item.isChecked;
    item.checkedAt = item.isChecked ? DateTime.now() : null;

    // Auto-complete list if all items are checked
    if (list.items.every((i) => i.isChecked)) {
      list.isCompleted = true;
      list.completedAt = DateTime.now();
    } else {
      list.isCompleted = false;
      list.completedAt = null;
    }

    return updateList(list);
  }

  Future<ShoppingListModel> addItemToList(
    ShoppingListModel list,
    CartItemEmbedded item,
  ) async {
    list.items = [...list.items, item];
    return updateList(list);
  }

  Future<ShoppingListModel> removeItemFromList(
    ShoppingListModel list,
    String itemUuid,
  ) async {
    list.items = list.items.where((i) => i.uuid != itemUuid).toList();
    return updateList(list);
  }

  Future<ShoppingListModel> markListComplete(ShoppingListModel list) async {
    list.isCompleted = true;
    list.completedAt = DateTime.now();
    for (final item in list.items) {
      item.isChecked = true;
    }
    return updateList(list);
  }

  // ── DELETE ───────────────────────────────────────────────────────────────
  Future<void> deleteList(int id) async {
    await _db.writeTxn(() async {
      await _db.shoppingListModels.delete(id);
    });
  }

  Future<void> deleteListByUuid(String uuid) async {
    final list = await getListByUuid(uuid);
    if (list != null) await deleteList(list.id);
  }

  Future<void> deleteListsForStore(String storeUuid) async {
    final lists = await getListsForStore(storeUuid);
    await _db.writeTxn(() async {
      await _db.shoppingListModels
          .deleteAll(lists.map((l) => l.id).toList());
    });
  }

  // ── STATS ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStats() async {
    final all = await getAllLists();
    final completed = all.where((l) => l.isCompleted).length;
    final totalItems = all.fold<int>(0, (s, l) => s + l.totalItems);
    final totalSpend = all.fold<double>(
        0, (s, l) => s + l.totalEstimatedCost);

    return {
      'totalLists': all.length,
      'completedLists': completed,
      'activeLists': all.length - completed,
      'totalItems': totalItems,
      'estimatedTotalSpend': totalSpend,
    };
  }
}
