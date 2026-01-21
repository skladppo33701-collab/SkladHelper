import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import 'package:sklad_helper_33701/core/theme.dart';
import 'package:sklad_helper_33701/shared/widgets/dialog_utils.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final bool _isUploading = false;

  // ───────────────── PASSWORD RESET FLOW ─────────────────

  Future<void> _showPasswordResetConfirmation(
    BuildContext context,
    String email,
  ) async {
    final proColors = Theme.of(context).extension<SkladColors>()!;

    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите email для сброса')));
      return;
    }

    await DialogUtils.showSkladDialog(
      context: context,
      title: 'Сброс пароля',
      icon: Icons.lock_reset_outlined,
      primaryButtonText: 'Отправить',
      secondaryButtonText: 'Отмена',
      showWarning: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Мы отправим ссылку для сброса пароля на вашу почту:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
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

        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
          if (!context.mounted) return;

          await DialogUtils.showSkladDialog(
            context: context,
            title: 'Письмо отправлено',
            icon: Icons.mark_email_read_outlined,
            primaryButtonText: 'Понятно',
            accentColorOverride: proColors.success,
            showWarning: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Инструкции по сбросу пароля были успешно отправлены на адрес:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: ${e.toString()}'),
              backgroundColor: proColors.error,
            ),
          );
        }
      },
      onSecondaryTap: () => Navigator.pop(context),
    );
  }

  // --- CHANGING EMAIL ---
  Future<void> _updateEmail(
    BuildContext context,
    String currentEmail,
    bool isDark,
  ) async {
    final controller = TextEditingController(text: currentEmail);
    final proColors = Theme.of(context).extension<SkladColors>()!;

    await DialogUtils.showSkladDialog(
      context: context,
      title: 'Изменение email',
      icon: Icons.email_outlined,
      primaryButtonText: 'Отправить',
      secondaryButtonText: 'Отмена',
      showWarning: true,
      warningText:
          'После отправки проверьте новый адрес — придёт письмо для подтверждения',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Введите новый адрес электронной почты',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              cursorColor: proColors.accentAction,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: proColors.accentAction,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "новый@email.com",
              ),
            ),
          ),
        ],
      ),
      onPrimaryTap: () async {
        final newEmail = controller.text.trim();

        if (newEmail.isEmpty || newEmail == currentEmail) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newEmail.isEmpty
                    ? 'Введите новый email'
                    : 'Это ваш текущий адрес',
              ),
              backgroundColor: proColors.error,
            ),
          );
          return;
        }

        Navigator.pop(context);

        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            throw Exception('Нет текущего пользователя');
          }

          // Modern safe method: sends verification to new email
          await user.verifyBeforeUpdateEmail(newEmail);

          // Optional: reload user to refresh local state
          await user.reload();

          if (!context.mounted) return;

          // Success dialog
          await DialogUtils.showSkladDialog(
            context: context,
            title: 'Проверьте новый email',
            icon: Icons.mark_email_read_outlined,
            primaryButtonText: 'Понятно',
            accentColorOverride: proColors.success,
            showWarning: true,
            warningText:
                'На новый адрес отправлено письмо с подтверждением.\nПосле клика по ссылке email обновится.',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Письмо отправлено на:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  newEmail,
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

          // Optional: update Firestore if you duplicate email there
          // await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'email': newEmail});
        } on FirebaseAuthException catch (e) {
          if (!context.mounted) return;

          String msg = 'Ошибка изменения email';
          if (e.code == 'requires-recent-login') {
            msg = 'Для безопасности войдите заново и повторите попытку';

            // Show reauth prompt
            final shouldReauth = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Требуется повторный вход'),
                content: const Text('Чтобы изменить email, войдите заново.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx, true);
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Войти заново'),
                  ),
                ],
              ),
            );

            if (shouldReauth == true && context.mounted) {
              // Redirect to login screen (adjust route name)
              Navigator.pushReplacementNamed(context, '/login');
            }
            return;
          } else if (e.code == 'invalid-email') {
            msg = 'Неверный формат email';
          } else if (e.code == 'email-already-in-use') {
            msg = 'Этот email уже занят';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: proColors.error),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Неизвестная ошибка: $e'),
              backgroundColor: proColors.error,
            ),
          );
        }
      },
      onSecondaryTap: () => Navigator.pop(context),
    );
  }

  // --- CHANGING PROFILE NAME ---
  Future<void> _updateProfileName(
    BuildContext context,
    String currentName,
    bool isDark,
  ) async {
    final controller = TextEditingController(text: currentName);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final proColors = Theme.of(context).extension<SkladColors>()!;

    return showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme.copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionHandleColor: proColors.accentAction,
            selectionColor: proColors.accentAction.withValues(alpha: 0.2),
            cursorColor: proColors.accentAction,
          ),
        ),
        child: AlertDialog(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          title: DialogUtils.buildUnifiedHeader(
            icon: Icons.person_outline,
            title: 'Изменить имя',
            accentColor: proColors.accentAction,
            textTheme: textTheme,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ваше текущее имя и фамилия. Вы можете изменить их ниже:',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  cursorColor: proColors.accentAction,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: proColors.accentAction,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: "Имя и Фамилия",
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          actions: [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userRoleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF1F5F9);
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;

    const primaryBlue = Color(0xFF1E3A8A);
    final proColors = Theme.of(context).extension<SkladColors>()!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Пользователь не найден'));
            }

            // ✅ REMOVED RefreshIndicator as requested
            // Photo updates now trigger automatically via setState and ref.invalidate
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                _buildProfileHeader(context, user, isDark, primaryBlue),
                const SizedBox(height: 24),

                // 1. Управление складом
                _buildSettingsGroup(context, 'Управление складом', cardColor, [
                  _buildTile(
                    Icons.cleaning_services_outlined,
                    'Кэш изображений',
                    'Очистить временные данные',
                    proColors.accentAction,
                    isDark: isDark,
                    showChevron: true, // ✅ Shows the '>' indicator
                    onTap: () {
                      PaintingBinding.instance.imageCache.clear();
                      PaintingBinding.instance.imageCache.clearLiveImages();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Кэш изображений очищен')),
                      );
                    },
                  ),
                  _buildTile(
                    Icons.vibration,
                    'Отклик сканера',
                    'Вибрация при чтении',
                    proColors.accentAction,
                    isDark: isDark,
                    trailing: Switch(
                      activeThumbColor: proColors.accentAction,
                      activeTrackColor: proColors.accentAction.withValues(
                        alpha: 0.4,
                      ),
                      value: true,
                      onChanged: (v) {},
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // 2. Аккаунт
                _buildSettingsGroup(context, 'Аккаунт', cardColor, [
                  _buildTile(
                    Icons.email_outlined,
                    'Почта',
                    user.email,
                    proColors.accentAction,
                    isDark: isDark,
                    showChevron: true, // ✅ Shows the '>' symbol
                    onTap: () => _updateEmail(context, user.email, isDark),
                  ),
                  _buildTile(
                    Icons.lock_reset_outlined,
                    'Сброс пароля',
                    'Отправить ссылку',
                    proColors.accentAction,
                    isDark: isDark,
                    showChevron: true, // ✅ Shows the '>' symbol
                    onTap: () =>
                        _showPasswordResetConfirmation(context, user.email),
                  ),
                  _buildTile(
                    Icons.telegram,
                    'Telegram ID',
                    user.telegramId ?? 'Не привязан',
                    const Color(0xFF24A1DE),
                    isDark: isDark,
                    showChevron: true,
                  ),
                ]),

                const SizedBox(height: 16),

                // 3. Интерфейс
                _buildSettingsGroup(context, 'Интерфейс', cardColor, [
                  _buildTile(
                    Icons.dark_mode_outlined,
                    'Темная тема',
                    'Переключить режим',
                    proColors.accentAction,
                    isDark: isDark,
                    trailing: Switch(
                      activeThumbColor: proColors.accentAction,
                      activeTrackColor: proColors.accentAction.withValues(
                        alpha: 0.4,
                      ),
                      value: ref.watch(themeModeProvider) == ThemeMode.dark,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).state = val
                            ? ThemeMode.dark
                            : ThemeMode.light;
                      },
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                // 4. Система
                _buildSettingsGroup(context, 'Система', cardColor, [
                  _buildTile(
                    Icons.logout,
                    'Выйти из системы',
                    'Завершить сессию',
                    Colors.redAccent,
                    isDark: isDark,
                    onTap: () => FirebaseAuth.instance.signOut(),
                    showChevron: true,
                  ),
                ]),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка: $e')),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AppUser user,
    bool isDark,
    Color blue,
  ) {
    // Use brighter blue for dark mode visibility
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final displayName = user.name.isNotEmpty ? user.name : "Пользователь";
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // --- PROFILE IMAGE SECTION ---
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  key: ValueKey(user.photoUrl), //
                  radius: 40,
                  backgroundImage:
                      user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(
                          // Add this timestamp to bypass Flutter and CDN caching
                          "${user.photoUrl!}?v=${DateTime.now().millisecondsSinceEpoch}",
                        )
                      : null,
                  child: _isUploading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : (user.photoUrl == null || user.photoUrl!.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              )
                            : null),
                ),
              ),

              // Camera Button with its own small "cutout" border
              Positioned(
                bottom: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => DialogUtils.buildUnifiedHeader,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: proColors
                            .accentAction, // Using your pro theme color
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // --- NAME SECTION (WITH EDIT ICON) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 32), // Spacer to balance the edit icon
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _updateProfileName(context, user.name, isDark),
                child: Icon(
                  Icons.edit,
                  size: 18,
                  color: proColors.accentAction,
                ),
              ),
            ],
          ),
          Text(
            user.email,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // --- ROLE BADGE ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: proColors.accentAction.withValues(
                alpha: isDark ? 0.15 : 0.08,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: proColors.accentAction.withValues(
                  alpha: isDark ? 0.4 : 0.2,
                ),
              ),
            ),
            child: Text(
              'КЛАДОВЩИК',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: proColors.accentAction,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          // --- STATS BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    'Сканы',
                    '1.2k',
                    proColors.accentAction,
                    isDark,
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  _buildStatItem(
                    'Задачи',
                    '42',
                    proColors.accentAction,
                    isDark,
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  _buildStatItem('Ранг', 'A', proColors.accentAction, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color, // Now uses adaptiveBlue
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark
                ? Colors.white54
                : Colors.grey, // Lighter text for dark mode
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    String title,
    Color cardColor,
    List<Widget> children,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.blueGrey[400] : Colors.blueGrey[800],
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: List.generate(children.length, (index) {
                return Column(
                  children: [
                    children[index],
                    if (index < children.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    Widget? trailing,
    VoidCallback? onTap, // Ensure this exists
    bool showChevron = false,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap, // ✅ Make sure this is assigned here
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white38 : Colors.grey,
        ),
      ),
      trailing:
          trailing ??
          (showChevron
              ? const Icon(Icons.chevron_right, size: 20, color: Colors.grey)
              : null),
    );
  }
}
