import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sklad_helper_33701/features/auth/models/user_model.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:sklad_helper_33701/features/auth/views/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:sklad_helper_33701/features/dashboard/views/manager_dashboard.dart';
import 'package:sklad_helper_33701/features/dashboard/views/loader_dashboard.dart';
import 'package:sklad_helper_33701/core/providers/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),

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
  // Define the timer variable so we can cancel it later
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // 2. Set up the periodic check every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload(); // Critical: Forces Firebase to check current status

      if (user != null && user.emailVerified) {
        timer.cancel();
        // 3. This triggers RootGate to rebuild and show the Dashboard
        ref.invalidate(authStateProvider);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Always clean up timers
    super.dispose();
  }

  Future<void> _openMailApp(BuildContext context) async {
    if (Platform.isAndroid) {
      // This is a direct command to the Android OS to open the Gmail Inbox
      final AndroidIntent intent = const AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.APP_EMAIL',
        // We force it to open in a new task so it doesn't "replace" your app
        flags: [0x10000000], // FLAG_ACTIVITY_NEW_TASK
      );

      try {
        await intent.launch();
        return;
      } catch (e) {
        debugPrint("Direct Intent failed: $e");
      }
    }

    // Fallback for iOS or if the above fails
    final Uri mailtoUri = Uri.parse("mailto:");
    if (await canLaunchUrl(mailtoUri)) {
      await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF051733), Color(0xFF000000)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 24),
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
                  "Ссылка для подтверждения отправлена на вашу почту. Пожалуйста, проверьте входящие сообщения или папку 'Спам'.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),

                // NEW: OPEN GMAIL BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      _openMailApp(context);
                    },
                    icon: const Icon(Icons.email),
                    label: const Text(
                      "Открыть Gmail",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

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
      ),
    );
  }
}
