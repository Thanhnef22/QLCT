import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'default_categories.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Missing authenticated user');

    try {
      await user.updateDisplayName(fullName.trim());
      await _ensureProfile(user, fullName.trim());
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Missing authenticated user');

    try {
      await _ensureProfile(
        user,
        user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.email!.split('@').first,
      );
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  Future<void> _ensureProfile(User user, String fullName) async {
    final profile = _firestore.collection('users').doc(user.uid);
    if ((await profile.get()).exists) return;

    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();
    batch.set(profile, {
      'fullName': fullName,
      'email': user.email ?? '',
      'createdAt': timestamp,
      'updatedAt': timestamp,
    });
    for (final category in DefaultCategories.all) {
      batch.set(profile.collection('categories').doc(category.id), {
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'type': category.type,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });
    }
    await batch.commit();
  }
}
