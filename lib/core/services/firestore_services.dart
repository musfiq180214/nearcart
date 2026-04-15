import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get stores => _db.collection('stores');
  CollectionReference get shoppingLists => _db.collection('shopping_lists');
  CollectionReference get users => _db.collection('users');
}