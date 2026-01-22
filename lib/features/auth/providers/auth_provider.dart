import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
// REQUIRED: Imports for Web Initialization
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import '../models/user_model.dart';

// --- GLOBAL PROVIDERS ---

// 1. 🔧 FIX: Global Web Initialization Provider
// This MUST be global so LoginScreen can watch it.
final googleSignInInitProvider = FutureProvider<void>((ref) async {
  if (kIsWeb) {
    // Explicitly initialize the web plugin parameters
    await (GoogleSignInPlatform.instance as web.GoogleSignInPlugin).initWithParams(
      const SignInInitParameters(
        clientId:
            '437534842036-9agg2s1gh3q02hijoagnhpulvgmtc3n0.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      ),
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
  // FIX: Use constructor with clientId for Web support
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '437534842036-9agg2s1gh3q02hijoagnhpulvgmtc3n0.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );

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
      // v7 Flow: authenticate() -> getters -> credential
      final account = await _googleSignIn.authenticate();
      final auth = account.authentication; // synchronous getter in v7

      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: null, // accessToken is handled internally in v7
      );

      await _handleFirebaseSignIn(credential);
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
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    state = AuthStatus.idle;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(
  () => AuthNotifier(),
);
