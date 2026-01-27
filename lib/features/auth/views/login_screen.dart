import 'package:sklad_helper_33701/core/constants/dimens.dart';
import 'package:sklad_helper_33701/shared/widgets/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:sklad_helper_33701/core/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.5, -0.75),
          radius: 1.5,
          colors: [
            Color(0xFF1E1B4B), // Deep Indigo
            Color(0xFF050206), // Black
          ],
          stops: [0.0, 0.8],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody:
                  false, // Ensures content scrolls if it gets too tall
              child: Padding(
                // Used gapXl (24) to maintain original design spacing,
                // though standard screen padding is paddingScreenH (16).
                padding: const EdgeInsets.symmetric(horizontal: Dimens.gapXl),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top spacing
                      SizedBox(height: size.height * 0.12),

                      _buildHeader(),
                      const SizedBox(height: Dimens.gap3xl), // 40.0
                      // Use the unified button for now.
                      _buildMobileButton(proColors),

                      const SizedBox(height: Dimens.gap2xl), // 32.0
                      _buildDivider(),
                      const SizedBox(height: Dimens.gap2xl), // 32.0
                      // --- Inputs ---
                      _buildTitleInput(
                        controller: _emailController,
                        title: 'Электронная почта',
                        hint: 'example@mail.com',
                        icon: Icons.alternate_email,
                        proColors: proColors,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final bool emailValid = RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                          ).hasMatch(value);
                          return emailValid ? null : 'Некорректный email';
                        },
                      ),
                      const SizedBox(height: Dimens.module), // 20.0
                      _buildTitleInput(
                        controller: _passwordController,
                        title: 'Пароль',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        proColors: proColors,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          return value.length < 6 ? 'Минимум 6 символов' : null;
                        },
                      ),

                      // --- Forgot Password ---
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topCenter,
                        child: _isLoginMode
                            ? Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: Dimens.gapS,
                                  ), // 8.0
                                  child: TextButton(
                                    onPressed: () {
                                      final email = _emailController.text
                                          .trim();
                                      _showPasswordResetConfirmation(
                                        context,
                                        email,
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Dimens.gapS, // 8.0
                                        vertical: Dimens.base, // 4.0
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Забыли пароль?',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: Dimens.gap2xl), // 32.0
                      // --- Primary Button ---
                      _buildPrimaryButton(proColors),

                      const Spacer(),

                      const SizedBox(height: Dimens.gapXl), // 24.0
                      _buildToggleLink(proColors),
                      const SizedBox(
                        height: 60,
                      ), // Keep specific bottom safe-area/spacer
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: Column(
        key: ValueKey<bool>(_isLoginMode),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isLoginMode ? 'С возвращением!' : 'Создать аккаунт',
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: Dimens.gapS), // 8.0
          Text(
            _isLoginMode
                ? 'Войдите, чтобы управлять складом'
                : 'Зарегистрируйтесь для начала работы',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileButton(SkladColors proColors) {
    return SizedBox(
      height: 56, // Standard button height
      child: OutlinedButton(
        onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.radiusFull), // 999.0
          ),
          side: BorderSide.none,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: Dimens.gapXl, // 24.0
              height: Dimens.gapXl, // 24.0
              child: SvgPicture.network(
                'https://www.svgrepo.com/show/475656/google-color.svg',
              ),
            ),
            const SizedBox(width: Dimens.gapM), // 12.0
            const Text('Google'),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.gapL), // 16.0
          child: Text(
            'или',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildTitleInput({
    required TextEditingController controller,
    required String title,
    required String hint,
    required IconData icon,
    required SkladColors proColors,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: Dimens.gapS), // 8.0
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: isPassword && _obscurePassword,
          cursorColor: proColors.accentAction,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            prefixIcon: Icon(
              icon,
              color: Colors.white54,
              size: Dimens.module,
            ), // 20.0
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white38,
                      size: Dimens.module, // 20.0
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: Dimens.module, // Snapped to 20.0 (was 18)
              horizontal: Dimens.paddingCard, // 16.0
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimens.radiusM), // 12.0
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimens.radiusM), // 12.0
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimens.radiusM), // 12.0
              borderSide: BorderSide(color: proColors.accentAction, width: 1.5),
            ),
            errorStyle: GoogleFonts.inter(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(SkladColors proColors) {
    return SizedBox(
      height: 56, // Standard button height
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            final email = _emailController.text.trim();
            final password = _passwordController.text.trim();
            String? error;
            if (_isLoginMode) {
              error = await ref
                  .read(authProvider.notifier)
                  .signIn(email, password);
            } else {
              error = await ref
                  .read(authProvider.notifier)
                  .signUp(email, password);
            }
            if (error != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    error,
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(Dimens.gapL), // 16.0
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Dimens.radiusM,
                    ), // Snapped to 12.0
                  ),
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: proColors.accentAction,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.radiusM), // 12.0
          ),
          elevation: 0,
        ),
        child: ref.watch(authProvider) == AuthStatus.loading
            ? const SizedBox(
                height: Dimens.gapXl, // 24.0
                width: Dimens.gapXl, // 24.0
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isLoginMode ? 'Войти' : 'Создать аккаунт',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleLink(SkladColors proColors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLoginMode ? 'Нет аккаунта?' : 'Уже есть аккаунт?',
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
        ),
        TextButton(
          onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
          child: Text(
            _isLoginMode ? 'Зарегистрироваться' : 'Войти',
            style: GoogleFonts.inter(
              color: proColors.accentAction,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showPasswordResetConfirmation(BuildContext context, String email) {
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите email')));
      return;
    }

    DialogUtils.showSkladDialog(
      context: context,
      title: 'Сброс пароля',
      icon: Icons.lock_reset_outlined,
      primaryButtonText: 'Отправить',
      secondaryButtonText: 'Отмена',
      showWarning: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Мы отправим ссылку для сброса пароля на вашу почту:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: Dimens.gapL), // 16.0
          Container(
            width: double.infinity,
            // Snapped padding to closest standards
            padding: const EdgeInsets.symmetric(
              vertical: Dimens.paddingCardCompact, // 12.0
              horizontal: Dimens.paddingCardCompact, // 12.0
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(
                Dimens.radiusL,
              ), // Snapped to 16.0
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      onPrimaryTap: () async {
        Navigator.pop(context);
        await _sendPasswordReset(context, email);
      },
      onSecondaryTap: () => Navigator.pop(context),
    );
  }

  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;

      DialogUtils.showSkladDialog(
        context: context,
        title: 'Письмо отправлено',
        icon: Icons.mark_email_read_outlined,
        primaryButtonText: 'Понятно',
        accentColorOverride: Theme.of(
          context,
        ).extension<SkladColors>()!.success,
        showWarning: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Инструкции по сбросу пароля были отправлены на:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: Dimens.gapM), // 12.0
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        onPrimaryTap: () => Navigator.pop(context),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
    }
  }
}
