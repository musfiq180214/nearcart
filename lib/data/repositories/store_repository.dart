import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';

class StoreRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('stores');

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> addStore(StoreModel store) async {
    await _col.doc(store.uuid).set(store.toJson());
  }

  Future<void> deleteStore(String uuid) async {
    await _col.doc(uuid).delete();
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// All stores in the app (for map view showing everyone's stores)
  Stream<List<StoreModel>> watchAllStores() {
    return _col.snapshots().map((snap) => snap.docs
        .map((d) => StoreModel.fromJson(d.data() as Map<String, dynamic>))
        .toList());
  }

  /// Only stores belonging to the current user
  Stream<List<StoreModel>> watchMyStores(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => StoreModel.fromJson(d.data() as Map<String, dynamic>))
        .toList());
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<List<StoreModel>> getStoresByCategory(String category) async {
    final res = await _col.where('category', isEqualTo: category).get();
    return res.docs
        .map((d) => StoreModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<StoreModel>> getStoresNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final res = await _col.get();
    final all = res.docs
        .map((d) => StoreModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();

    return all
        .where((s) =>
    _haversine(lat, lng, s.latitude, s.longitude) <= radiusKm)
        .toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * (pi / 180);
}