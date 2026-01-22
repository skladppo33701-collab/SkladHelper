import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Project Imports
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/models/user_model.dart';

// Views
import 'features/auth/views/login_screen.dart';
import 'features/dashboard/views/manager_dashboard.dart';
import 'features/dashboard/views/loader_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: SkladApp()));
}

class SkladApp extends ConsumerWidget {
  const SkladApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Sklad Helper',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: SkladTheme.lightTheme,
      darkTheme: SkladTheme.darkTheme,

      // FIX: Add all necessary delegates here
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate, // Required for text direction
        GlobalCupertinoLocalizations
            .delegate, // Required for text fields/copy-paste
      ],
      supportedLocales: const [Locale('ru')],

      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userRoleAsync = ref.watch(userRoleProvider);

    return authState.when(
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        return userRoleAsync.when(
          data: (appUser) {
            if (appUser == null) {
              return const _LoadingScaffold(message: "Создание профиля...");
            }

            switch (appUser.role) {
              case UserRole.manager:
                return const ManagerDashboard();
              case UserRole.loader:
                return const LoaderDashboard();
              default:
                return _ErrorScaffold(
                  message: "Ваша роль (${appUser.role}) не поддерживается.",
                  onLogout: () => FirebaseAuth.instance.signOut(),
                );
            }
          },
          loading: () => const _LoadingScaffold(message: "Загрузка данных..."),
          error: (err, stack) => _ErrorScaffold(
            message: "Ошибка профиля: $err",
            onLogout: () => FirebaseAuth.instance.signOut(),
          ),
        );
      },
      loading: () => const _LoadingScaffold(message: "Проверка входа..."),
      error: (err, stack) =>
          _ErrorScaffold(message: "Ошибка авторизации: $err", onLogout: null),
    );
  }
}

// --- HELPER WIDGETS ---

class _LoadingScaffold extends StatelessWidget {
  final String message;
  const _LoadingScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0F1A)
          : const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback? onLogout;

  const _ErrorScaffold({required this.message, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (onLogout != null)
                ElevatedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Выйти"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
