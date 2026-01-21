import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sklad_helper_33701/features/auth/models/user_model.dart';
import 'package:flutter/foundation.dart';

// 1. Watching the raw Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. Fetches the User Role from Firestore with live updates
final userRoleProvider = StreamProvider<AppUser?>((ref) {
  final authUser = ref.watch(authStateProvider).value;

  if (authUser == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return AppUser.fromMap(doc.data()!, authUser.uid);
      });
});

enum AuthStatus { idle, loading, authenticated, error }

class AuthNotifier extends Notifier<AuthStatus> {
  // v7+ uses a Singleton, so we don't instantiate it with 'new'
  final _googleSignIn = GoogleSignIn.instance;

  @override
  AuthStatus build() {
    return AuthStatus.idle;
  }

  // --- SIGN IN (Email/Password) ---
  Future<String?> signIn(String email, String password) async {
    state = AuthStatus.loading;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AuthStatus.authenticated;
      return null;
    } on FirebaseAuthException catch (e) {
      state = AuthStatus.error;
      if (e.code == 'user-not-found') return 'Пользователь не найден';
      if (e.code == 'wrong-password') return 'Неверный пароль';
      return 'Ошибка входа: ${e.message}';
    } catch (e) {
      state = AuthStatus.error;
      return 'Произошла ошибка';
    }
  }

  // --- SIGN UP (Email/Password) ---
  Future<String?> signUp(String email, String password) async {
    state = AuthStatus.loading;
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'email': email,
              'role': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            });
        ref.invalidate(userRoleProvider);
      }
      state = AuthStatus.authenticated;
      return null;
    } catch (e) {
      state = AuthStatus.error;
      return 'Ошибка регистрации';
    }
  }

  // --- GOOGLE SIGN IN (Corrected for v7+) ---
  Future<void> signInWithGoogle() async {
    state = AuthStatus.loading;
    try {
      // 1. Initialize (Required in v7)
      await _googleSignIn.initialize();

      // 2. Authenticate
      // Note: 'authenticate' usually throws if cancelled in v7, making the result non-nullable.
      final googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // 3. Get Access Token (FIX: Must usage authorizeScopes now)
      final authResponse = await googleUser.authorizationClient.authorizeScopes(
        ['email', 'profile'],
      );
      final accessToken = authResponse.accessToken;

      // 4. Get ID Token (FIX: Still available on authentication property)
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      // 5. Create Credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken, // From authorizationClient
        idToken: idToken, // From authentication
      );

      // 6. Firebase Sign In
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
      // Cancellation or error triggers this
      state = AuthStatus.error;
      debugPrint("Google Sign In Error: $e");
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    state = AuthStatus.idle;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(() {
  return AuthNotifier();
});
