import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:random_password_generator/random_password_generator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sklad_helper_33701/core/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isWandActive = false;

  void _generateStrongPassword() {
    final generator = RandomPasswordGenerator();
    String newPassword = generator.randomPassword(
      letters: true,
      uppercase: true,
      numbers: true,
      specialChar: true,
      passwordLength: 12,
    );
    setState(() {
      _passwordController.text = newPassword;
      _obscurePassword = false;
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

    final proColors = Theme.of(context).extension<SkladColors>()!;

    return Container(
      decoration: BoxDecoration(
        // Removed const
        gradient: RadialGradient(
          center: const Alignment(-0.5, -0.75),
          radius: 1.5,
          colors: [proColors.surfaceLow, const Color(0xFF050206)],
          stops: const [0.0, 0.8],
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
                          _buildHeader(),
                          const SizedBox(height: 40),
                          _buildSocialButton(),
                          const SizedBox(height: 28),
                          _buildDivider(),
                          const SizedBox(height: 18),
                          _buildGlassInput(
                            controller: _emailController,
                            hint: 'Электронная почта',
                            proColors: proColors,
                          ),
                          const SizedBox(height: 15),
                          _buildGlassInput(
                            controller: _passwordController,
                            hint: 'Пароль',
                            isPassword: true,
                            proColors: proColors,
                          ),
                          if (_isLoginMode)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  final email = _emailController.text.trim();
                                  _showPasswordResetConfirmation(
                                    context,
                                    email,
                                    proColors,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  splashFactory: NoSplash.splashFactory,
                                  padding: const EdgeInsets.only(
                                    top: 12,
                                    bottom: 20,
                                  ),
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
                          _buildMainButton(proColors),
                          const Spacer(),
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
          splashFactory: NoSplash.splashFactory,
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
    required SkladColors proColors,
    bool isPassword = false,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionHandleColor: proColors.accentAction,
          selectionColor: proColors.accentAction.withValues(alpha: 0.3),
          cursorColor: proColors.accentAction,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: proColors.accentAction,
        cursorWidth: 2,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
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
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: proColors.accentAction, width: 1.2),
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
                              size: 24,
                              color: _isWandActive
                                  ? proColors.accentAction
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      IconButton(
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 24,
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

  Widget _buildMainButton(SkladColors proColors) {
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
          backgroundColor: proColors.surfaceHigh,
          foregroundColor: Colors.white,
          elevation: 0,
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
                  color: Colors.white,
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
          child: Text(
            _isLoginMode ? 'Создать' : 'Войти',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
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

  Future<void> _showPasswordResetConfirmation(
    BuildContext context,
    String email,
    SkladColors proColors,
  ) async {
    final theme = Theme.of(context);

    return showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme.copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionHandleColor: proColors.accentAction,
            cursorColor: proColors.accentAction,
          ),
        ),
        child: AlertDialog(
          backgroundColor: proColors.surfaceLow,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          titlePadding: EdgeInsets.zero,
          title: _buildUnifiedHeader(
            Icons.lock_reset_outlined,
            'Сброс пароля',
            proColors.accentAction,
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
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: _buildDialogAction(
                    'Отмена',
                    () => Navigator.pop(context),
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDialogAction(
                    'Отправить',
                    () async {
                      Navigator.pop(context);
                      await _sendPasswordReset(context, email, proColors);
                    },
                    isPrimary: true,
                    color: proColors.accentAction,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedHeader(IconData icon, String title, Color color) {
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
    VoidCallback onTap, {
    required bool isPrimary,
    Color? color,
  }) {
    return SizedBox(
      height: 44,
      child: isPrimary
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
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
              ),
              onPressed: onTap,
              child: Text(text, style: const TextStyle(color: Colors.white70)),
            ),
    );
  }

  Future<void> _sendPasswordReset(
    BuildContext context,
    String email,
    SkladColors proColors,
  ) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ссылка для сброса отправлена на вашу почту'),
          backgroundColor: proColors.accentAction,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
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
