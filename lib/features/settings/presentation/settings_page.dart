import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:image_cropper/image_cropper.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isUploading = false;

  // ───────────────── PASSWORD RESET DIALOG ─────────────────
  Future<void> _showPasswordResetConfirmation(
    BuildContext context,
    String email,
  ) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final adaptiveBlue = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF1E3A8A);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: _buildUnifiedHeader(
          Icons.lock_reset_outlined,
          'Сброс пароля',
          adaptiveBlue,
          colors,
          textTheme,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Мы отправим ссылку для сброса пароля на вашу почту:',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            // Consistent Rounded Box showing the email
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Text(
                email,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: adaptiveBlue,
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        actions: [
          _buildDialogAction(
            'Отмена',
            () => Navigator.pop(context),
            colors,
            isPrimary: false,
          ),
          const SizedBox(width: 12),
          _buildDialogAction(
            'Отправить',
            () async {
              Navigator.pop(context); // Close dialog
              await _sendPasswordReset(context, email); // Trigger the email
            },
            colors,
            isPrimary: true,
            color: adaptiveBlue,
          ),
        ],
      ),
    );
  }

  // --- CHANGING EMAIL ---
  Future<void> _updateEmail(
    BuildContext context,
    String currentEmail,
    bool isDark,
  ) async {
    final controller = TextEditingController(text: currentEmail);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final adaptiveBlue = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF1E3A8A);

    return showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme.copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionHandleColor: adaptiveBlue,
            selectionColor: adaptiveBlue.withValues(alpha: 0.2),
            cursorColor: adaptiveBlue,
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
          title: _buildUnifiedHeader(
            Icons.alternate_email_rounded,
            'Изменить почту',
            adaptiveBlue,
            colors,
            textTheme,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Введите новый адрес. Вам придет письмо для подтверждения.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              // Rounded Box exactly like Reset Password
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
                  cursorColor: adaptiveBlue,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: adaptiveBlue,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: "example@mail.com",
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          actions: [
            _buildDialogAction(
              'Отмена',
              () => Navigator.pop(context),
              colors,
              isPrimary: false,
            ),
            const SizedBox(width: 12),
            _buildDialogAction(
              'Сохранить',
              () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // 1. Update Auth Email (Sends a verification email to the NEW address)
                    await user.verifyBeforeUpdateEmail(controller.text.trim());

                    // 2. Update Firestore document to keep data in sync
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'email': controller.text.trim()});

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Проверьте новую почту для подтверждения',
                        ),
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'requires-recent-login') {
                    // User needs to log out and back in to change email
                    _showErrorSnackBar(
                      context,
                      'Требуется повторный вход в систему',
                    );
                  }
                }
              },
              colors,
              isPrimary: true,
              color: adaptiveBlue,
            ),
          ],
        ),
      ),
    );
  }

  // --- REFINED UPLOAD FUNCTION (WITH CROPPER) ---
  Future<void> _updateProfilePicture(BuildContext context, String uid) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1E3A8A);
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Редактировать',
          toolbarColor: primaryBlue,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: primaryBlue,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          backgroundColor: isDark ? Colors.black : Colors.white,
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
      final dio = Dio();
      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          croppedFile.path,
          filename: "$uid.jpg",
        ),
        "upload_preset": "sklad_helper_preset",
      });

      final response = await dio.post(
        "https://api.cloudinary.com/v1_1/dukgkpmqw/image/upload",
        data: formData,
      );

      if (response.statusCode == 200 && response.data['secure_url'] != null) {
        final String imageUrl = response.data['secure_url'];

        // 🔥 Updated to photoUrl to match your new UserModel naming
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'photoUrl': imageUrl,
        });

        ref.invalidate(userRoleProvider);

        // ✅ FIXED: Check context.mounted specifically before using ScaffoldMessenger
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Фото успешно обновлено'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
    } finally {
      // ✅ Using State.mounted for setState is correct
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
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
    final adaptiveBlue = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF1E3A8A);

    return showDialog(
      context: context,
      builder: (context) => Theme(
        // Force the selection handle and cursor to be Blue, not Purple
        data: theme.copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionHandleColor: adaptiveBlue,
            selectionColor: adaptiveBlue.withValues(alpha: 0.2),
            cursorColor: adaptiveBlue,
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
          title: _buildUnifiedHeader(
            Icons.badge_outlined,
            'Личные данные',
            adaptiveBlue,
            colors,
            textTheme,
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
                  cursorColor: adaptiveBlue,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: adaptiveBlue,
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
          actions: [
            _buildDialogAction(
              'Отмена',
              () => Navigator.pop(context),
              colors,
              isPrimary: false,
            ),
            const SizedBox(width: 12),
            _buildDialogAction(
              'Сохранить',
              () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Update Firestore with the new name
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'name': controller.text.trim()});

                    // Refresh the provider to show the new name immediately
                    ref.invalidate(userRoleProvider);

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Данные успешно обновлены')),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  _showErrorSnackBar(context, 'Ошибка сохранения: $e');
                }
              },
              colors,
              isPrimary: true,
              color: adaptiveBlue,
            ),
          ],
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
    final adaptiveBlue = isDark ? const Color(0xFF60A5FA) : primaryBlue;

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
                    adaptiveBlue,
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
                    adaptiveBlue,
                    isDark: isDark,
                    trailing: Switch(
                      activeThumbColor: adaptiveBlue,
                      activeTrackColor: adaptiveBlue.withValues(alpha: 0.4),
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
                    adaptiveBlue,
                    isDark: isDark,
                    showChevron: true, // ✅ Shows the '>' symbol
                    onTap: () => _updateEmail(context, user.email, isDark),
                  ),
                  _buildTile(
                    Icons.lock_reset_outlined,
                    'Сброс пароля',
                    'Отправить ссылку',
                    adaptiveBlue,
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
                    adaptiveBlue,
                    isDark: isDark,
                    trailing: Switch(
                      activeThumbColor: adaptiveBlue,
                      activeTrackColor: adaptiveBlue.withValues(alpha: 0.4),
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
    final adaptiveBlue = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF1E3A8A);
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
                  // ✅ FIX 1: Remove DateTime from the Key.
                  // Only change the key if the URL itself changes.
                  key: ValueKey(user.photoUrl),
                  radius: 40,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  backgroundImage:
                      !_isUploading &&
                          user.photoUrl != null &&
                          user.photoUrl!.isNotEmpty
                      // ✅ FIX 2: Remove ?v= timestamp here.
                      // Since Cloudinary now generates unique IDs, we don't need to force a reload on every build.
                      ? NetworkImage(user.photoUrl!)
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
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _updateProfilePicture(context, user.uid),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color:
                          cardColor, // This creates the "gap" between the photo and the blue button
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: blue,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
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
                child: Icon(Icons.edit, size: 18, color: adaptiveBlue),
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
              color: adaptiveBlue.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: adaptiveBlue.withValues(alpha: isDark ? 0.4 : 0.2),
              ),
            ),
            child: Text(
              'КЛАДОВЩИК',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: adaptiveBlue,
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
                  _buildStatItem('Сканы', '1.2k', adaptiveBlue, isDark),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  _buildStatItem('Задачи', '42', adaptiveBlue, isDark),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  _buildStatItem('Ранг', 'A', adaptiveBlue, isDark),
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

  // ───────────────── DIALOG HEADER HELPER ─────────────────
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
        color: colors.onSurface.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ───────────────── SNACKBAR HELPER ─────────────────
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ───────────────── DIALOG BUTTON HELPER ─────────────────
  Widget _buildDialogAction(
    String text,
    VoidCallback onTap,
    ColorScheme colors, {
    required bool isPrimary,
    Color? color,
  }) {
    return SizedBox(
      height: 48,
      width: 120,
      child: isPrimary
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: onTap,
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: BorderSide(color: colors.outlineVariant),
              ),
              onPressed: onTap,
              child: Text(
                text,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
    );
  }

  // ───────────────── PASSWORD RESET LOGIC ─────────────────
  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!context.mounted) return;

      // Show a formal success dialog instead of just a SnackBar
      _showResetSuccessDialog(context, email);
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Ошибка: ${e.toString()}');
    }
  }

  // ───────────────── RESET SUCCESS DIALOG ─────────────────
  void _showResetSuccessDialog(BuildContext context, String email) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final adaptiveBlue = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF1E3A8A);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        titlePadding: EdgeInsets.zero,
        title: _buildUnifiedHeader(
          Icons.mark_email_read_outlined,
          'Письмо отправлено',
          Colors.green, // Success color
          colors,
          textTheme,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Инструкции по сбросу пароля были отправлены на адрес:',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              email,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Если вы не видите письма, обязательно проверьте папку "Спам".',
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.amber[200] : Colors.amber[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        actions: [
          _buildDialogAction(
            'Понятно',
            () => Navigator.pop(context),
            colors,
            isPrimary: true,
            color: adaptiveBlue,
          ),
        ],
      ),
    );
  }
}
