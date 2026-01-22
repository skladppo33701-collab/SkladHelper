import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

// --- GLOBAL PROVIDERS ---

// 1. Global Web Initialization Provider
final googleSignInInitProvider = FutureProvider<void>((ref) async {
  if (kIsWeb) {
    // v7: Initialize the singleton instance.
    // This replaces the old 'initWithParams' method.
    await GoogleSignIn.instance.initialize(
      clientId:
          '437534842036-9agg2s1gh3q02hijoagnhpulvgmtc3n0.apps.googleusercontent.com',
    );
  }
});

// 2. Auth State
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 3. User Role
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
  // v7: Use the singleton instance directly
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  AuthStatus build() => AuthStatus.idle;

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

  Future<void> signInWithGoogle() async {
    state = AuthStatus.loading;
    try {
      // Ensure Web initialization is complete
      if (kIsWeb) {
        await ref.read(googleSignInInitProvider.future);
      }

      // v7: authenticate() returns a non-nullable Future<GoogleSignInAccount>.
      // It throws a GoogleSignInException if the user cancels.
      final account = await _googleSignIn.authenticate();

      // v7: 'authentication' is now a synchronous getter (REMOVE 'await')
      final auth = account.authentication;

      // v7: 'auth' does NOT contain accessToken anymore.
      // For Firebase Sign-In, we only strictly need the idToken.
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: null,
      );

      await _handleFirebaseSignIn(credential);
    } on GoogleSignInException catch (e) {
      // This block catches cancellation (user closed the window)
      state = AuthStatus.idle;
      debugPrint("Google Sign In Cancelled: ${e.toString()}");
    } catch (e) {
      state = AuthStatus.error;
      debugPrint("Google Sign In Error: $e");
    }
  }

  Future<void> _handleFirebaseSignIn(AuthCredential credential) async {
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
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      state = AuthStatus.idle;
    } catch (e) {
      debugPrint("Sign Out Error: $e");
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(
  () => AuthNotifier(),
);
