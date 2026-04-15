import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../auth_repo.dart';
import '../data/models/store_model.dart';
import '../data/models/shopping_list_model.dart';

import '../data/models/user_model.dart';
import '../data/repositories/store_repository.dart';
import '../data/repositories/shopping_list_firestore_repo.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

final storeRepositoryProvider =
Provider<StoreRepository>((_) => StoreRepository());

final shoppingListRepositoryProvider =
Provider<ShoppingListFirestoreRepository>(
        (_) => ShoppingListFirestoreRepository());

final firestoreProvider =
Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

// ── Auth State ────────────────────────────────────────────────────────────────

/// Raw Firebase auth stream
// lib/core/providers.dart

// Change this:
// lib/core/providers.dart

// Use the repository you already defined at the top of the file
final firebaseAuthUserProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges; // Access the stream from your repo
});
/// Whether a user is currently signed in
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(firebaseAuthUserProvider).value != null;
});

/// Current Firebase UID (null when signed out)
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(firebaseAuthUserProvider).value?.uid;
});

// ── Auth Notifier ─────────────────────────────────────────────────────────────

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.idle,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repo.register(name: name, email: email, password: password);
      state = state.copyWith(status: AuthStatus.success, user: user);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _friendlyError(e.code),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repo.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success, user: user);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _friendlyError(e.code),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.idle, errorMessage: null);
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

final authNotifierProvider =
StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// ── Location ──────────────────────────────────────────────────────────────────

class LocationState {
  final double? lat;
  final double? lng;
  final bool isLoading;
  final String? error;

  const LocationState({this.lat, this.lng, this.isLoading = false, this.error});

  bool get hasLocation => lat != null && lng != null;
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState());

  void setLoading() => state = const LocationState(isLoading: true);
  void setLocation(double lat, double lng) =>
      state = LocationState(lat: lat, lng: lng);
  void setError(String err) => state = LocationState(error: err);
}

final locationProvider =
StateNotifierProvider<LocationNotifier, LocationState>(
        (_) => LocationNotifier());

// ── Stores ────────────────────────────────────────────────────────────────────

/// All stores in the app (map view)
final allStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  return ref.read(storeRepositoryProvider).watchAllStores();
});

/// Only the current user's stores (home screen + add/delete)
final myStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.read(storeRepositoryProvider).watchMyStores(uid);
});

// ── Shopping Lists ────────────────────────────────────────────────────────────

/// All lists for the current user
final allListsProvider = StreamProvider<List<ShoppingListModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.read(shoppingListRepositoryProvider).watchMyLists(uid);
});

/// Lists for a specific store, scoped to current user
final listsForStoreProvider =
StreamProvider.family<List<ShoppingListModel>, String>((ref, storeUuid) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref
      .read(shoppingListRepositoryProvider)
      .watchListsForStore(storeUuid, uid);
});

// ── Stats ─────────────────────────────────────────────────────────────────────

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return {'totalLists': 0, 'activeLists': 0, 'completedLists': 0};
  // Re-fetch whenever lists change
  ref.watch(allListsProvider);
  return ref.read(shoppingListRepositoryProvider).getStats(uid);
});