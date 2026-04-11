import 'package:isar/isar.dart';
import '../models/store_model.dart';
import 'isar_service.dart';

class StoreRepository {
  final IsarService _isarService;

  StoreRepository(this._isarService);

  Isar get _db => _isarService.db;

  // ── CREATE ──────────────────────────────────────────────────────────────
  Future<StoreModel> addStore(StoreModel store) async {
    await _db.writeTxn(() async {
      await _db.storeModels.put(store);
    });
    return store;
  }

  // ── READ ─────────────────────────────────────────────────────────────────
  Future<List<StoreModel>> getAllStores() async {
    return _db.storeModels.where().sortByName().findAll();
  }

  Future<StoreModel?> getStoreByUuid(String uuid) async {
    return _db.storeModels.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<List<StoreModel>> getStoresByCategory(String category) async {
    return _db.storeModels.filter().categoryEqualTo(category).findAll();
  }

  Stream<List<StoreModel>> watchAllStores() {
    return _db.storeModels.where().watch(fireImmediately: true);
  }

  // ── UPDATE ───────────────────────────────────────────────────────────────
  Future<StoreModel> updateStore(StoreModel store) async {
    store.updatedAt = DateTime.now();
    await _db.writeTxn(() async {
      await _db.storeModels.put(store);
    });
    return store;
  }

  // ── DELETE ───────────────────────────────────────────────────────────────
  Future<void> deleteStore(int id) async {
    await _db.writeTxn(() async {
      await _db.storeModels.delete(id);
    });
  }

  Future<void> deleteStoreByUuid(String uuid) async {
    final store = await getStoreByUuid(uuid);
    if (store != null) await deleteStore(store.id);
  }

  // ── NEARBY ───────────────────────────────────────────────────────────────
  /// Returns stores within [radiusKm] kilometers of [lat],[lng]
  Future<List<StoreModel>> getStoresNearby({
    required double lat,
    required double lng,
    double radiusKm = 2.0,
  }) async {
    final all = await getAllStores();
    return all.where((s) {
      final dist = _haversineKm(lat, lng, s.latitude, s.longitude);
      return dist <= radiusKm;
    }).toList()
      ..sort((a, b) {
        final da = _haversineKm(lat, lng, a.latitude, a.longitude);
        final db = _haversineKm(lat, lng, b.latitude, b.longitude);
        return da.compareTo(db);
      });
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = _sin2(dLat / 2) +
        _cos(_rad(lat1)) * _cos(_rad(lat2)) * _sin2(dLon / 2);
    final c = 2 * _asin(_sqrt(a));
    return r * c;
  }

  double _rad(double deg) => deg * 3.14159265358979 / 180;
  double _sin2(double x) => _sin(x) * _sin(x);
  double _sin(double x) => x - x * x * x / 6 + x * x * x * x * x / 120;
  double _cos(double x) => 1 - x * x / 2 + x * x * x * x / 24;
  double _asin(double x) => x + x * x * x / 6;
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
