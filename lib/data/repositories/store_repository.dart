import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firestore_services.dart';
import '../models/store_model.dart';

class StoreRepository {
  final FirestoreService _firestore;

  StoreRepository(this._firestore);

  // ✅ CREATE STORE
  Future<void> addStore(StoreModel store) async {
    await _firestore.stores.doc(store.uuid).set(store.toJson());
  }

  // ✅ REALTIME STREAM (used in your map)
  Stream<List<StoreModel>> watchAllStores() {
    return _firestore.stores.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          StoreModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // ✅ CATEGORY FILTER
  Future<List<StoreModel>> getStoresByCategory(String category) async {
    final res = await _firestore.stores
        .where('category', isEqualTo: category)
        .get();

    return res.docs
        .map((doc) =>
        StoreModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // ✅ NEARBY STORES (basic version)
  Future<List<StoreModel>> getStoresNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final res = await _firestore.stores.get();

    final allStores = res.docs
        .map((doc) =>
        StoreModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    // simple distance filter
    return allStores.where((store) {
      final distance = _calculateDistance(
        lat,
        lng,
        store.latitude,
        store.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  // ✅ HAVERSINE
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
            cos(_deg2rad(lat1)) *
                cos(_deg2rad(lat2)) *
                (sin(dLon / 2) * sin(dLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);
}