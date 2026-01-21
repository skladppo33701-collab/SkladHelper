import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import 'package:sklad_helper_33701/core/theme.dart';
import 'package:sklad_helper_33701/shared/widgets/dialog_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dio/dio.dart';
import 'package:sklad_helper_33701/features/inventory/providers/task_stats_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isUploading = false;

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

  // ───────────────── EMAIL CHANGE FLOW ─────────────────
  Future<void> _updateEmail(
    BuildContext context,
    String currentEmail,
    bool isDark,
  ) async {
    final controller = TextEditingController(text: currentEmail);
    final proColors = Theme.of(context).extension<SkladColors>()!;

    await DialogUtils.showSkladDialog(
      context: context,
      title: 'Изменение почты',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
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
      onPrimaryTap: () {
        // your logic
        Navigator.pop(context);
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
            title: 'Изменить имя и фамилию',
            color: proColors.accentAction,
            colors: colors,
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
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType
                    .emailAddress, // or TextInputType.name for name dialog
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                cursorColor: proColors.accentAction,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: proColors.accentAction,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: "Имя Фамилия",
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: proColors.accentAction.withValues(alpha: 0.3),
                      width: 1.0, // thin
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: proColors.accentAction.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: proColors.accentAction, // full accent on focus
                      width: 0.5, // slightly thicker on focus
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ), // proper inner space
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ), // ↓ less bottom padding
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: DialogUtils.buildDialogAction(
                    context: context,
                    text: 'Отмена',
                    onTap: () => Navigator.pop(context),
                    isPrimary: false,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DialogUtils.buildDialogAction(
                    context: context,
                    text: 'Отправить',
                    onTap: () async {
                      final newName = controller.text.trim();
                      if (newName.isNotEmpty && newName != currentName) {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .update({'name': newName});

                          ref.invalidate(userRoleProvider);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Имя сохранено')),
                            );
                          }
                        }
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    isPrimary: true,
                    colors: colors,
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

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userRoleProvider);
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: proColors.surfaceLow,
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Пользователь не найден'));
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              key: const PageStorageKey('settings_scroll_key'),
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                _buildProfileHeader(context, user, isDark, colors.primary),
                const SizedBox(height: 24),

                // 1. Управление складом
                _buildSettingsGroup(
                  context,
                  'Управление складом',
                  proColors.surfaceHigh,
                  [
                    // surfaceHigh
                    _buildTile(
                      Icons.cleaning_services_outlined,
                      'Кэш изображений',
                      'Очистить временные данные',
                      proColors.accentAction,
                      isDark: isDark,
                      showChevron: true,
                      onTap: () {
                        PaintingBinding.instance.imageCache.clear();
                        PaintingBinding.instance.imageCache.clearLiveImages();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Кэш изображений очищен',
                              style: textTheme.bodySmall,
                            ),
                          ),
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
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Аккаунт
                _buildSettingsGroup(context, 'Аккаунт', proColors.surfaceHigh, [
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
                _buildSettingsGroup(
                  context,
                  'Интерфейс',
                  proColors.surfaceHigh,
                  [
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
                  ],
                ),

                const SizedBox(height: 16),

                // 4. Система
                _buildSettingsGroup(context, 'Система', proColors.surfaceHigh, [
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
    Color primary,
  ) {
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final colors = Theme.of(context).colorScheme;
    final cardColor = proColors.surfaceHigh;
    final displayName = user.name.isNotEmpty ? user.name : "Пользователь";
    final dividerColor = proColors.neutralGray.withValues(alpha: 0.1);

    // 1. Providers
    final taskCountAsync = ref.watch(taskCountProvider);
    final scansAsync = ref.watch(userScansProvider);
    final rankAsync = ref.watch(activityRankProvider);

    // 2. Resolve Values

    final taskCountString = taskCountAsync.when(
      data: (val) => val.toString(),
      loading: () => '...',
      error: (err, _) => '0',
    );

    final scansString = scansAsync.when(
      data: (val) => val.toString(),
      loading: () => '...',
      error: (err, _) => '0',
    );

    final rankString = rankAsync.value ?? '-';

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
                  color: proColors.neutralGray.withValues(alpha: 0.02),
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
                  key: ValueKey(user.photoUrl),
                  radius: 40,
                  backgroundImage:
                      user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(
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
              Positioned(
                bottom: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) _updateProfilePicture(context, uid);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: proColors.accentAction,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 32),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
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
            style: TextStyle(color: proColors.neutralGray, fontSize: 13),
          ),
          const SizedBox(height: 16),
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
          Divider(height: 1, color: dividerColor),

          // --- STATS BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Сканы',
                      scansString, // Connected!
                      proColors.accentAction,
                      isDark,
                    ),
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: dividerColor),
                  Expanded(
                    child: _buildStatItem(
                      'Задачи',
                      taskCountString, // Connected!
                      proColors.accentAction,
                      isDark,
                    ),
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: dividerColor),
                  Expanded(
                    child: _buildStatItem(
                      'Активность',
                      rankString, // Connected!
                      proColors.accentAction,
                      isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: proColors.neutralGray,
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
    final proColors = Theme.of(context).extension<SkladColors>()!;

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
              color: isDark ? proColors.neutralGray : Colors.blueGrey[800],
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
              color: proColors.neutralGray.withValues(alpha: 0.05),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children:
                  children, // updated to not have hardcoded dividers; add if needed
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
    final colors = Theme.of(context).colorScheme;
    final proColors = Theme.of(context).extension<SkladColors>()!;
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
          color: colors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: proColors.neutralGray),
      ),
      trailing:
          trailing ??
          (showChevron
              ? const Icon(Icons.chevron_right, size: 20, color: Colors.grey)
              : null),
    );
  }

  Future<void> _updateProfilePicture(BuildContext context, String uid) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final proColors = theme.extension<SkladColors>()!;

    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // ↑ allow higher resolution (still reasonable for pfp)
      maxHeight: 800,
      imageQuality:
          85, // ↑ 85–90 is sweet spot: good quality + small file (~300–800 KB)
    );

    if (image == null) return;

    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Редактировать',
          toolbarColor: proColors.surfaceLow,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: proColors.accentAction,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          backgroundColor: isDark ? const Color(0xFF020617) : Colors.white,
        ),
        IOSUiSettings(
          title: 'Редактировать',
          cancelButtonTitle: 'Отмена',
          doneButtonTitle: 'Готово',
        ),
      ],
    );

    if (croppedFile == null) return;

    setState(() => _isUploading = true);

    try {
      const String cloudName = "dukgkpmqw";
      const String uploadPreset =
          "sklad_helper_preset"; // confirm this is correct in Cloudinary dashboard

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(croppedFile.path),
        "upload_preset": uploadPreset,
        "quality": "auto:good", // ← Cloudinary auto, but good quality
        "fetch_format":
            "auto", // auto webp/avif for better compression without loss
        "resource_type": "image",
      });

      var response = await Dio().post(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
        data: formData,
        onSendProgress: (sent, total) {
          debugPrint(
            'Upload progress: ${(sent / total * 100).toStringAsFixed(1)}% ($sent/$total bytes)',
          );
        },
      );

      if (response.statusCode == 200 && response.data['secure_url'] != null) {
        final String secureUrl = response.data['secure_url'];

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'photoUrl': secureUrl,
        });

        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        if (!context.mounted) return;
        ref.invalidate(userRoleProvider);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Фото сохранено')));
      } else {
        throw Exception(
          'Cloudinary response error: ${response.statusCode} - ${response.data}',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки фото: $e'),
          backgroundColor: proColors.error,
        ),
      );
      debugPrint('PFP error: $e'); // check console for details
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
