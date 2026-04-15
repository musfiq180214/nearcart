import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../models/shopping_list_model.dart';
import '../repositories/shopping_list_firestore_repo.dart';

final firestoreServiceProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final shoppingListRepositoryProvider =
Provider<ShoppingListFirestoreRepository>((ref) {
  return ShoppingListFirestoreRepository();
});


final listsForStoreProvider =
StreamProvider.family<List<ShoppingListModel>, String>((ref, storeUuid) {
  final repo = ref.read(shoppingListRepositoryProvider);

  final userId = ref.read(authRepositoryProvider).currentUser?.uid;

  if (userId == null) {
    return const Stream.empty();
  }

  return repo.watchListsForStore(storeUuid, userId);
});