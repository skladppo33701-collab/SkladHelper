import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:random_password_generator/random_password_generator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controllers for text input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State to toggle between Login and Sign Up
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isWandActive = false; // Add this line
  // NEW: Generator Function
  void _generateStrongPassword() {
    final generator = RandomPasswordGenerator();

    // The correct method is .randomPassword()
    // Parameters: letters, uppercase, numbers, special, length
    String newPassword = generator.randomPassword(
      letters: true,
      uppercase: true,
      numbers: true,
      specialChar: true,
      passwordLength: 12,
    );

    setState(() {
      _passwordController.text = newPassword;
      _obscurePassword =
          false; // Show it so they can see the generated password
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthStatus>(authProvider, (previous, next) {
      if (next == AuthStatus.error) {
        _showError('Ошибка входа. Проверьте данные.');
      }
    });

    return Container(
      // 1. PREMIUM BACKGROUND GRADIENT
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.5, -0.75),
          radius: 1.5,
          colors: [
            Color(0xFF051733), // Your Blue Glow
            Color(0xFF050206), // Deep Black
          ],
          stops: [0.0, 0.8],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60),

                          // 2. DYNAMIC HEADER
                          _buildHeader(),

                          const SizedBox(height: 40),

                          // 3. GOOGLE SOCIAL BUTTON
                          _buildSocialButton(),

                          const SizedBox(height: 28),

                          // 4. DIVIDER
                          _buildDivider(),

                          const SizedBox(height: 18),

                          // 5. INPUT FIELDS
                          _buildGlassInput(
                            controller: _emailController,
                            hint: 'Электронная почта',
                          ),
                          const SizedBox(height: 15),
                          _buildGlassInput(
                            controller: _passwordController,
                            hint: 'Пароль',
                            isPassword: true,
                          ),

                          // 6. FORGOT PASSWORD (Only in Login Mode)
                          // Inside your build method's Column
                          if (_isLoginMode)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  final email = _emailController.text.trim();
                                  _showPasswordResetConfirmation(
                                    context,
                                    email,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  splashFactory: NoSplash.splashFactory,
                                  overlayColor: Colors
                                      .transparent, // Stops the long-press glow
                                  padding: const EdgeInsets.only(
                                    top: 12,
                                    bottom: 20,
                                  ), // Controlled padding
                                ),
                                child: Text(
                                  'Забыли пароль?',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 30),

                          // 7. MAIN ACTION BUTTON
                          _buildMainButton(),

                          const Spacer(), // Pushes toggle to the bottom
                          // 8. DYNAMIC TOGGLE LINK
                          _buildToggleLink(),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENT HELPERS ---

  Widget _buildHeader() {
    return Text(
      _isLoginMode ? 'Войдите в\nSkladHelper' : 'Создайте\nаккаунт',
      style: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.1,
        letterSpacing: -1.0,
      ),
    );
  }

  Widget _buildSocialButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _showError('Вход через Google будет доступен скоро'),
        icon: const Icon(Icons.g_mobiledata, color: Colors.black, size: 30),
        label: Text(
          _isLoginMode ? 'Войти через Google' : 'Регистрация через Google',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: const StadiumBorder(),
          elevation: 0,
          // REMOVES RIPPLE AND LONG-PRESS HIGHLIGHT
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'или через почту',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
  }) {
    // Your Darker Royal Blue for the premium dark theme
    const adaptiveBlue = Color(0xFFA78BFA);

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          selectionHandleColor: adaptiveBlue, // The 'Drop' symbol
          selectionColor: Color(0x4D1E3A8A), // Highlight color (30% opacity)
          cursorColor: adaptiveBlue, // Carrot color
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: adaptiveBlue,
        cursorWidth: 2,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          // 1. IS_DENSE and CONTENT_PADDING fix the excessive height
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 0,
          ),

          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
          ),
          // 2. FOCUSED BORDER - Thicker and Darker Blue
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: adaptiveBlue, width: 1.2),
          ),

          suffixIconConstraints: const BoxConstraints(
            minHeight: 24,
            minWidth: 24,
          ),
          suffixIcon: isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isLoginMode)
                        GestureDetector(
                          onTap: () async {
                            if (_isWandActive) return;
                            setState(() => _isWandActive = true);
                            _generateStrongPassword();
                            await Future.delayed(
                              const Duration(milliseconds: 150),
                            );
                            if (mounted) setState(() => _isWandActive = false);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.auto_fix_high,
                              size: 24, // Increased size
                              color: _isWandActive
                                  ? adaptiveBlue
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      IconButton(
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        splashColor: Colors.transparent, // Kill ripple
                        highlightColor: Colors.transparent, // Kill ripple
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 24, // Increased size
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    final authStatus = ref.watch(authProvider);
    final isLoading = authStatus == AuthStatus.loading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();
                if (email.isEmpty || password.isEmpty) {
                  _showError('Заполните все поля');
                  return;
                }
                if (_isLoginMode) {
                  ref.read(authProvider.notifier).login(email, password);
                } else {
                  ref.read(authProvider.notifier).signUp(email, password);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.white,
          elevation: 0,
          splashFactory: NoSplash.splashFactory, // No ripple
          overlayColor: Colors.transparent, // No long-press highlight
          shape: StadiumBorder(
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white, // Or use adaptiveBlue for the spinner
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _isLoginMode ? 'Войти' : 'Создать аккаунт',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLoginMode ? 'Нет аккаунта?' : 'Уже есть аккаунт?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory, // Kill ripple
            foregroundColor: Colors.white,
          ),
          child: Text(
            _isLoginMode ? 'Создать' : 'Войти',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ───────────────── PASSWORD RESET DIALOG ─────────────────
  Future<void> _showPasswordResetConfirmation(
    BuildContext context,
    String email,
  ) async {
    final theme = Theme.of(context);
    const adaptiveBlue = Color(0xFFA78BFA); // Using your Royal Blue

    return showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme.copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: adaptiveBlue,
            cursorColor: adaptiveBlue,
          ),
        ),
        child: AlertDialog(
          backgroundColor: const Color(0xFF111827),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          titlePadding: EdgeInsets.zero,
          title: _buildUnifiedHeader(
            Icons.lock_reset_outlined,
            'Сброс пароля',
            adaptiveBlue,
            theme.colorScheme,
            theme.textTheme,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Мы отправим ссылку для сброса пароля на вашу почту:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  email.isEmpty ? "email@example.com" : email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Changed to white for visibility
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          actions: [
            Row(
              // Use a Row to prevent button overflow
              children: [
                Expanded(
                  child: _buildDialogAction(
                    'Отмена',
                    () => Navigator.pop(context),
                    theme.colorScheme,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDialogAction(
                    'Отправить',
                    () async {
                      Navigator.pop(context);
                      await _sendPasswordReset(context, email);
                    },
                    theme.colorScheme,
                    isPrimary: true,
                    color: adaptiveBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ───────────────── DIALOG HELPERS ─────────────────

  Widget _buildUnifiedHeader(
    IconData icon,
    String title,
    Color color,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogAction(
    String text,
    VoidCallback onTap,
    ColorScheme colors, {
    required bool isPrimary,
    Color? color,
  }) {
    return SizedBox(
      height: 44,
      width: 110,
      child: isPrimary
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
                splashFactory: NoSplash.splashFactory, // Removes ripple
              ),
              onPressed: onTap,
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: const BorderSide(color: Colors.white24),
                splashFactory: NoSplash.splashFactory, // Removes ripple
              ),
              onPressed: onTap,
              child: Text(text, style: const TextStyle(color: Colors.white70)),
            ),
    );
  }

  // ───────────────── PASSWORD RESET LOGIC ─────────────────
  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    try {
      // 1. Trigger the Firebase reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!context.mounted) return;

      // 2. Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ссылка для сброса отправлена на вашу почту'),
          backgroundColor: const Color(0xFF6366F1), // Using a vibrant Indigo
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      // 3. Handle specific Firebase errors
      String message = 'Ошибка при отправке';
      if (e.code == 'user-not-found') {
        message = 'Пользователь с такой почтой не найден';
      } else if (e.code == 'invalid-email') {
        message = 'Некорректный адрес почты';
      }
      _showError(message);
    } catch (e) {
      if (!context.mounted) return;
      _showError('Произошла ошибка: $e');
    }
  }
}
