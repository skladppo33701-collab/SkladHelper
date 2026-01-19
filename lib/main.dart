import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sklad_helper_33701/features/auth/models/user_model.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:sklad_helper_33701/features/auth/views/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:sklad_helper_33701/features/dashboard/views/manager_dashboard.dart';
import 'package:sklad_helper_33701/features/dashboard/views/loader_dashboard.dart';
import 'package:sklad_helper_33701/core/providers/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sklad_helper_33701/core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // --- FIX: Add these 3 lines for Russian Language support ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'), // Set Russian as supported
      ],
      locale: const Locale('ru', 'RU'), // Force the app to use Russian
      // -----------------------------------------------------------
      home: const RootGate(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // This routes to the dashboard based on the user's role provider
          final userRole = ref.watch(userRoleProvider);
          return userRole.when(
            data: (appUser) {
              if (appUser?.role == UserRole.manager) {
                return const ManagerDashboard();
              }
              return const LoaderDashboard();
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const LoginScreen(),
          );
        }
        return const LoginScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const LoginScreen(),
    );
  }
}

// 3. This widget decides if we go to Login or Dashboard
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This now watches the STREAM from auth_provider.dart.
    // Every time the 'role' changes in Firestore, this variable updates.
    final userAsync = ref.watch(userRoleProvider);

    return userAsync.when(
      // main.dart - inside RootGate build method
      data: (AppUser? user) {
        if (user == null) return const LoginScreen();

        final authUser = FirebaseAuth.instance.currentUser;

        // 1. If they haven't clicked the link in Gmail, they STAY here
        if (authUser != null && !authUser.emailVerified) {
          return const VerificationPendingScreen();
        }

        // 2. Once verified, check the role
        if (user.role == UserRole.manager) {
          return const ManagerDashboard();
        } else {
          // 3. FIX: Show LoaderDashboard for 'pending' or 'loader' roles
          // This ensures they aren't stuck on the "Email Sent" screen!
          return const LoaderDashboard();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      ),
      error: (err, stack) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Ошибка: $err"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text("Вернуться к входу"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VerificationPendingScreen extends ConsumerStatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  ConsumerState<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState
    extends ConsumerState<VerificationPendingScreen> {
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Start checking every 3 seconds
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerification(),
    );
  }

  Future<void> _checkEmailVerification() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload(); // Refresh the user's data from Firebase

      if (user?.emailVerified ?? false) {
        _timer?.cancel();
        if (mounted) {
          // Tell Riverpod to re-run the auth check now that the user is verified
          ref.invalidate(authStateProvider);
        }
      }
    } catch (e) {
      debugPrint("Error checking verification: $e");
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // CRITICAL: Stop the timer when the widget is destroyed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Matching our Midnight Blue theme
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(height: 32),
              const Text(
                "Подтвердите почту",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Ссылка для подтверждения отправлена на вашу почту. Пожалуйста, проверьте входящие сообщения.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // NEW: Manual Refresh Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isChecking ? null : _checkEmailVerification,
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Я уже подтвердил",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text(
                  "Вернуться к входу",
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
