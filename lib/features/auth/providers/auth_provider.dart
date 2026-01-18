import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sklad_helper_33701/features/auth/models/user_model.dart';
import 'package:flutter/foundation.dart';

// 1. Watching the raw Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. RE-ADDED: Fetches the User Role from Firestore
// lib/features/auth/providers/auth_provider.dart

// CHANGE: From FutureProvider to StreamProvider
// lib/features/auth/providers/auth_provider.dart

// 1. Change FutureProvider to StreamProvider
final userRoleProvider = StreamProvider<AppUser?>((ref) {
  // Watch the auth state to get the current UID
  final authUser = ref.watch(authStateProvider).value;

  if (authUser == null) {
    return Stream.value(null);
  }

  // 2. Use .snapshots() instead of .get() to listen for live changes
  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        // 3. Map the live data to your AppUser model
        return AppUser.fromMap(doc.data()!, authUser.uid);
      });
});

// 3. Auth Status Enum
enum AuthStatus { idle, loading, authenticated, error }

// 4. RIVERPOD 3.0 NOTIFIER
class AuthNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    return AuthStatus.idle;
  }

  // REAL FIREBASE LOGIN
  Future<void> login(String email, String password) async {
    state = AuthStatus.loading;
    try {
      // Replaced simulation with real Firebase Auth call
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AuthStatus.authenticated;
    } on FirebaseAuthException catch (e) {
      state = AuthStatus.error;
      // You can print the specific error to help with debugging
      debugPrint('Firebase Login Error: ${e.code}');
    } catch (e) {
      state = AuthStatus.error;
    }
  }

  Future<void> signUp(String email, String password) async {
    state = AuthStatus.loading;
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // 1. Send the email first
        await userCredential.user!.sendEmailVerification();

        // 2. Create the Firestore document with 'pending' role
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'email': email,
              'role': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            });

        // 3. REFRESH: This forces RootGate to fetch the 'pending' role immediately
        // so it knows to show the VerificationPendingScreen instead of LoginScreen.
        ref.invalidate(userRoleProvider);
      }

      // 4. Set state to authenticated so the UI knows the process is done
      state = AuthStatus.authenticated;
    } catch (e) {
      state = AuthStatus.error;
      debugPrint("Sign Up Error: $e");
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(() {
  return AuthNotifier();
});
