import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

/// 🔐 Firebase auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 👤 Firestore user + role
final userRoleProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return AppUser.fromMap(doc.data()!, user.uid);
      });
});

enum AuthStatus { idle, loading, authenticated, error }

class AuthNotifier extends Notifier<AuthStatus> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  AuthStatus build() {
    return AuthStatus.idle;
  }

  /// 🔧 REQUIRED for v7 (call once at app start)
  Future<void> initGoogle() async {
    await _googleSignIn.initialize(
      clientId: kIsWeb ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com' : null,
    );
  }

  /// 📧 Email login
  Future<String?> signIn(String email, String password) async {
    state = AuthStatus.loading;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AuthStatus.authenticated;
      return null;
    } catch (e) {
      state = AuthStatus.error;
      return e.toString();
    }
  }

  /// 🆕 Email signup
  Future<String?> signUp(String email, String password) async {
    state = AuthStatus.loading;
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'email': email,
            'role': 'loader',
            'createdAt': FieldValue.serverTimestamp(),
          });

      state = AuthStatus.authenticated;
      return null;
    } catch (e) {
      state = AuthStatus.error;
      return e.toString();
    }
  }

  /// 🔵 Google Sign-In (OFFICIAL v7 FLOW)
  Future<void> signInWithGoogle() async {
    state = AuthStatus.loading;

    try {
      final account = await _googleSignIn.authenticate();

      final auth = account.authentication;

      // ✅ v7 ONLY supports idToken
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'email': userCredential.user!.email,
              'role': 'loader',
              'createdAt': FieldValue.serverTimestamp(),
              'name': userCredential.user!.displayName ?? 'New User',
            });
      }

      state = AuthStatus.authenticated;
    } catch (e) {
      state = AuthStatus.error;
    }
  }

  /// 🚪 Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    state = AuthStatus.idle;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(
  () => AuthNotifier(),
);
