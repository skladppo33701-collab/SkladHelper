import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:sklad_helper_33701/features/auth/views/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:sklad_helper_33701/features/dashboard/views/manager_dashboard.dart';
import 'package:sklad_helper_33701/features/dashboard/views/loader_dashboard.dart';
import 'package:sklad_helper_33701/core/providers/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sklad_helper_33701/core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  // Fixed: Added named key parameter
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Sklad Helper',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: SkladTheme.lightTheme,
      darkTheme: SkladTheme.darkTheme,
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate],
      supportedLocales: const [Locale('ru')],
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasData) {
            return const RoleBasedScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

class RoleBasedScreen extends ConsumerWidget {
  const RoleBasedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);

    return userRole.when(
      data: (user) {
        // Fixed: Ensure string comparison works or use proper Enum values
        final role = user?.role.toString().split('.').last;

        if (role == 'manager') {
          return const ManagerDashboard();
        } else if (role == 'loader') {
          return const LoaderDashboard();
        } else {
          FirebaseAuth.instance.signOut();
          return const LoginScreen();
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) {
        // Fixed: Changed __ to _
        FirebaseAuth.instance.signOut();
        return const LoginScreen();
      },
    );
  }
}

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: proColors.surfaceLow,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 80,
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              "Подтвердите почту",
              style: textTheme.titleLarge?.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              "Мы отправили ссылку на вашу почту. Перейдите по ней для активации аккаунта.",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.currentUser?.reload();

                // Fixed: Added mounted check for async gap
                if (!context.mounted) return;

                if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Почта ещё не подтверждена")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: proColors.accentAction,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                "Я уже подтвердил",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: Text(
                "Вернуться к входу",
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
