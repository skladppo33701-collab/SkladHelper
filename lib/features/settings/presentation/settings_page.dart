import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

// Core & Theme
import '../../../../core/theme.dart';
import '../../../../core/constants/dimens.dart';
import '../../../../core/utils/cropper/cropper_helper.dart';
import '../../../../core/utils/upload/upload_helper.dart';
import '../../../../core/providers/theme_provider.dart';

// Features
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATE PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

class VibrationNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool val) => state = val;
}

final vibrationProvider = NotifierProvider<VibrationNotifier, bool>(
  VibrationNotifier.new,
);

class NotificationNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
}

final notificationsProvider = NotifierProvider<NotificationNotifier, bool>(
  NotificationNotifier.new,
);

// Note: Usage removed from UI but provider kept if needed elsewhere
final userCreatedTasksProvider = StreamProvider.autoDispose<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('tasks')
      .where('creatorId', isEqualTo: user.uid)
      .snapshots()
      .map((s) => s.docs.length);
});

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS PAGE (Sovereign Design System)
// ─────────────────────────────────────────────────────────────────────────────

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isUploading = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {
      if (mounted) setState(() => _appVersion = '1.0');
    }
  }

  // --- Revised Sovereign Notifications (High Contrast) ---
  void _showSovereignNotification(
    String message,
    IconData icon,
    Color accentColor,
    SkladColors colors,
  ) {
    if (!mounted) return;

    // Use a high contrast background (Dark on light mode, Light on dark mode)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.paddingCard, // 16
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userRoleProvider);
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surfaceLow,
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text("Нет данных"));

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // 1. COLLAPSIBLE APP BAR
              SliverAppBar(
                expandedHeight: 140.0,
                floating: false,
                pinned: true,
                backgroundColor: colors.surfaceLow,
                elevation: 0,
                scrolledUnderElevation: 0,
                systemOverlayStyle: isDark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                leading: const SizedBox(), // Hide default back button
                leadingWidth: 0,
                actions: [
                  // Exit Button - Pinned to right
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: IconButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: Icon(
                        Icons.logout_rounded,
                        color: colors.error,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.error.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(10),
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  // [ALIGNMENT FIX] Bottom 16px ensures it centers vertically in collapsed 56px height
                  // Left 24px matches the general padding
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  expandedTitleScale: 1.6,
                  title: Text(
                    'Настройки',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: colors.contentPrimary,
                      // Ensure font matches the identity card style
                    ),
                  ),
                ),
              ),

              // 2. IDENTITY CARD
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildIdentityCard(context, user, colors, isDark),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // 3. SETTINGS LIST
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('ПРИЛОЖЕНИЕ', colors),
                    _buildSettingsGroup(
                      context,
                      colors,
                      children: [
                        _buildToggleRow(
                          'Уведомления',
                          Icons.notifications_outlined,
                          ref.watch(notificationsProvider),
                          (v) =>
                              ref.read(notificationsProvider.notifier).toggle(),
                          colors,
                        ),
                        _buildDivider(colors),
                        _buildToggleRow(
                          'Вибрация',
                          Icons.vibration_outlined,
                          ref.watch(vibrationProvider),
                          (v) => ref.read(vibrationProvider.notifier).set(v),
                          colors,
                        ),
                        _buildDivider(colors),
                        _buildToggleRow(
                          'Темная тема',
                          Icons.dark_mode_outlined,
                          ref.watch(themeModeProvider) == ThemeMode.dark,
                          (v) => ref.read(themeModeProvider.notifier).state = v
                              ? ThemeMode.dark
                              : ThemeMode.light,
                          colors,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('АККАУНТ', colors),
                    _buildSettingsGroup(
                      context,
                      colors,
                      children: [
                        _buildNavRow(
                          'Email',
                          user.email,
                          Icons.mail_outline_rounded,
                          colors,
                          () => _showEditSheet(
                            context,
                            'Изменить Email',
                            user.email,
                            (v) async {
                              if (v.isNotEmpty) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .update({'email': v});
                                if (!mounted) return;
                                ref.invalidate(userRoleProvider);
                                _showSovereignNotification(
                                  'Email успешно обновлен',
                                  Icons.check_circle_rounded,
                                  colors.success,
                                  colors,
                                );
                              }
                            },
                            isEmail: true,
                          ),
                        ),
                        _buildDivider(colors),
                        _buildNavRow(
                          'Пароль',
                          'Обновить',
                          Icons.lock_outline_rounded,
                          colors,
                          () => _showPasswordResetSheet(
                            context,
                            user.email,
                            colors,
                          ),
                        ),
                        _buildDivider(colors),
                        _buildNavRow(
                          'Кэш данных',
                          'Очистить',
                          Icons.cleaning_services_outlined,
                          colors,
                          () {
                            PaintingBinding.instance.imageCache.clear();
                            PaintingBinding.instance.imageCache
                                .clearLiveImages();
                            _showSovereignNotification(
                              'Кэш успешно очищен',
                              Icons.cleaning_services_rounded,
                              colors.accentAction,
                              colors,
                            );
                          },
                        ),
                      ],
                    ),
                  ]),
                ),
              ),

              // 4. VERSION AT BOTTOM
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 48, bottom: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Sklad Helper",
                          style: GoogleFonts.outfit(
                            color: colors.contentPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Версия $_appVersion",
                          style: GoogleFonts.inter(
                            color: colors.contentTertiary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.accentAction),
        ),
        error: (e, _) => Center(
          child: Text("Ошибка загрузки", style: TextStyle(color: colors.error)),
        ),
      ),
    );
  }

  // ───────────────── WIDGETS ─────────────────

  Widget _buildIdentityCard(
    BuildContext context,
    AppUser user,
    SkladColors colors,
    bool isDark,
  ) {
    // [ROLE LOGIC UPDATE] Only allow Loader/Storekeeper
    String roleDisplay = 'Сотрудник';
    Color roleColor = colors.contentSecondary;

    try {
      final r = user.role.name.toLowerCase();
      if (r.contains('storekeeper')) {
        roleDisplay = 'Кладовщик';
        roleColor = colors.accentAction;
      } else if (r.contains('loader')) {
        roleDisplay = 'Грузчик';
        roleColor = const Color(0xFFF59E0B); // Amber
      }
      // Everything else defaults to 'Сотрудник' and neutral color
    } catch (_) {
      // Fallback
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.divider),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Picture with Gradient
          GestureDetector(
            onTap: () => _updateProfilePicture(context, user.uid),
            child: Container(
              // [PFP UPDATE] Thinner circle padding (3.0 -> 1.5)
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colors.accentAction,
                    colors.accentAction.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: colors.surfaceContainer,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: _isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.accentAction,
                          ),
                        )
                      : (user.photoUrl == null
                            ? Icon(
                                Icons.person_rounded,
                                size: 32,
                                color: colors.neutralGray,
                              )
                            : null),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Badge (Restricted to Loader/Storekeeper)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleDisplay.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Name
                Text(
                  user.name.isEmpty ? 'Без имени' : user.name,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.contentPrimary,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Email
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.contentSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Edit Button (Minimal)
          IconButton(
            onPressed: () => _showEditSheet(
              context,
              'Редактировать имя',
              user.name,
              (val) async {
                if (val.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'name': val});
                  if (!mounted) return;
                  ref.invalidate(userRoleProvider);
                  _showSovereignNotification(
                    'Имя успешно обновлено',
                    Icons.check_circle_rounded,
                    colors.success,
                    colors,
                  );
                }
              },
            ),
            icon: Icon(
              Icons.edit_rounded,
              size: 20,
              color: colors.contentTertiary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    SkladColors colors, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildToggleRow(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    SkladColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildIconContainer(icon, colors),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.contentPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            },
            activeThumbColor: colors.accentAction,
            activeTrackColor: colors.accentAction.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(
    String title,
    String? subtitle,
    IconData icon,
    SkladColors colors,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              _buildIconContainer(icon, colors),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.contentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.contentTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.contentTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, SkladColors colors) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: colors.contentSecondary, size: 20),
    );
  }

  Widget _buildSectionHeader(String title, SkladColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: colors.contentTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDivider(SkladColors colors) {
    return Divider(height: 1, thickness: 1, indent: 70, color: colors.divider);
  }

  // ───────────────── IMPROVED SHEETS ─────────────────

  void _showEditSheet(
    BuildContext context,
    String title,
    String current,
    Function(String) onSave, {
    bool isEmail = false,
  }) {
    final controller = TextEditingController(text: current);
    final theme = Theme.of(context);
    final colors = theme.extension<SkladColors>()!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colors.surfaceHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.contentTertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.contentPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Введите новые данные для обновления",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.contentSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors.contentPrimary,
              ),
              keyboardType: isEmail
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              cursorColor: colors.accentAction,
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surfaceContainer,
                hintText: "Введите значение...",
                hintStyle: TextStyle(color: colors.contentTertiary),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.accentAction, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  // [STYLE UPDATE] Thin stroke cancel button
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.divider, width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Отмена',
                      style: GoogleFonts.inter(
                        color: colors.contentSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onSave(controller.text.trim());
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentAction,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Сохранить',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // [STYLE UPDATE] Modernized Password Reset Sheet
  void _showPasswordResetSheet(
    BuildContext context,
    String email,
    SkladColors colors,
  ) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colors.surfaceHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.contentTertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 32,
                color: colors.warning,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Сброс пароля",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.contentPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Мы отправим ссылку для создания нового пароля на ваш email:",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.contentSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.contentPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // [STYLE UPDATE] Changed to Row layout with thin-stroke Cancel
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.divider, width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Отмена',
                      style: GoogleFonts.inter(
                        color: colors.contentSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: email,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _showSovereignNotification(
                          'Письмо отправлено на почту',
                          Icons.mark_email_read_rounded,
                          colors.success,
                          colors,
                        );
                      } catch (_) {
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentAction,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Отправить',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfilePicture(BuildContext context, String uid) async {
    final picker = ImagePicker();
    final colors = context.colors;

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (image == null) return;

    final processed = await cropImageIfPossible(image);
    if (processed == null) return;

    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      final fileToUpload = await UploadHelper.prepareUploadFile(
        processed,
        image,
      );
      FormData formData = FormData.fromMap({
        "file": fileToUpload,
        "upload_preset": "sklad_helper_preset",
        "quality": "auto:good",
        "resource_type": "image",
      });

      var response = await Dio().post(
        "https://api.cloudinary.com/v1_1/dukgkpmqw/image/upload",
        data: formData,
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['secure_url'] != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'photoUrl': response.data['secure_url'],
        });
        PaintingBinding.instance.imageCache.clear();
        ref.invalidate(userRoleProvider);
        _showSovereignNotification(
          'Фото профиля обновлено',
          Icons.camera_alt_rounded,
          colors.accentAction,
          colors,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSovereignNotification(
          'Ошибка загрузки фото',
          Icons.error_outline_rounded,
          colors.error,
          colors,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
