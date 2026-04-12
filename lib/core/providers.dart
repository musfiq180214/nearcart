import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearcart/core/services/firestore_services.dart';
import 'package:nearcart/data/repositories/shopping_list_firestore_repo.dart';
import '../data/providers/shopping_list_repo_provider.dart';
import '../data/repositories/isar_service.dart';
import '../data/repositories/store_repository.dart';
import '../data/repositories/shopping_list_repository.dart';
import '../data/models/store_model.dart';
import '../data/models/shopping_list_model.dart';

// ── SERVICE PROVIDERS ────────────────────────────────────────────────────────



final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository(ref.read(firestoreServiceProvider));
});


// ── STORE PROVIDERS ──────────────────────────────────────────────────────────

final allStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.watchAllStores();
});

final storesByCategoryProvider =
    FutureProvider.family<List<StoreModel>, String>((ref, category) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStoresByCategory(category);
});

final nearbyStoresProvider = FutureProvider.family<List<StoreModel>,
    ({double lat, double lng, double radius})>((ref, params) {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStoresNearby(
    lat: params.lat,
    lng: params.lng,
    radiusKm: params.radius,
  );
});



// ── LOCATION STATE ───────────────────────────────────────────────────────────

class LocationState {
  final double? lat;
  final double? lng;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.lat,
    this.lng,
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    double? lat,
    double? lng,
    bool? isLoading,
    String? error,
  }) =>
      LocationState(
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );

  bool get hasLocation => lat != null && lng != null;
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState());

  void setLocation(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng, isLoading: false, error: null);
  }

  void setLoading() {
    state = state.copyWith(isLoading: true, error: null);
  }

  void setError(String error) {
    state = state.copyWith(isLoading: false, error: error);
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(),
);

// ── SELECTED STORE ────────────────────────────────────────────────────────────

final selectedStoreProvider = StateProvider<StoreModel?>((ref) => null);

// ── MAP FILTER ────────────────────────────────────────────────────────────────

final mapCategoryFilterProvider = StateProvider<String?>((ref) => null);


final allListsProvider = StreamProvider<List<ShoppingListModel>>((ref) {
  final repo = ref.read(shoppingListRepositoryProvider);
  return repo.watchAllLists();
});

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(shoppingListRepositoryProvider);
  return repo.getStats();
});