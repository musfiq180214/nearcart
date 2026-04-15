import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream of auth state changes ──────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Register ──────────────────────────────────────────────────────────────
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user!.updateDisplayName(name.trim());

    final user = UserModel(
      uid: credential.user!.uid,
      name: name.trim(),
      email: email.trim(),
      createdAt: DateTime.now(),
    );

    // Persist user profile in Firestore
    await _db.collection('users').doc(user.uid).set(user.toJson());

    return user;
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final doc =
    await _db.collection('users').doc(credential.user!.uid).get();

    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }

    // Fallback if Firestore profile is missing
    return UserModel(
      uid: credential.user!.uid,
      name: credential.user!.displayName ?? 'User',
      email: credential.user!.email ?? '',
      createdAt: DateTime.now(),
    );
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();

  // ── Fetch profile ─────────────────────────────────────────────────────────
  Future<UserModel?> fetchCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }
}