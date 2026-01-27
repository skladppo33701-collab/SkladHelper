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

final userCreatedTasksProvider = StreamProvider.autoDispose<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);

  // Changed collection from 'assignments' to 'tasks' per previous logic
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

  // --- Sovereign Notifications (Consistent with Inventory Page) ---
  void _showSovereignNotification(
    String message,
    IconData icon,
    Color accentColor,
    SkladColors colors,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.paddingCard, // 16
            vertical: Dimens.gapM, // 12
          ),
          decoration: BoxDecoration(
            color: colors.surfaceHigh.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(Dimens.radiusL), // 16
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimens.gapS), // 8
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: Dimens.gapM), // 12
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: colors.contentPrimary,
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
      backgroundColor: colors.surfaceLow, // "Executive Slate" background
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text("Нет данных"));

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. HEADER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimens.gapXl, // 24
                    52, // Top Safe Area approx
                    Dimens.gapXl, // 24
                    Dimens.gapL, // 16
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Настройки',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: colors.contentPrimary,
                          fontSize: 26,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        icon: Icon(
                          Icons.logout_rounded,
                          color: colors.error,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.error.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Dimens.radiusM,
                            ), // 12
                          ),
                          padding: const EdgeInsets.all(Dimens.gapS), // 8
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. IDENTITY CARD
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.gapXl,
                  ), // 24
                  child: _buildIdentityCard(context, user, colors, isDark),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: Dimens.gapL),
              ), // 16
              // 3. STATS GRID (Bento Style)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.gapXl,
                ), // 24
                sliver: SliverToBoxAdapter(
                  child: _buildStatsGrid(context, colors),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: Dimens.gapXl),
              ), // 24
              // 4. SETTINGS LIST
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.gapXl,
                ), // 24
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

                    const SizedBox(height: Dimens.gapXl), // 24
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
                            'Новый Email',
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
                          'Изменить',
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
                          'Данные',
                          'Очистить кэш',
                          Icons.cleaning_services_outlined,
                          colors,
                          () {
                            PaintingBinding.instance.imageCache.clear();
                            PaintingBinding.instance.imageCache
                                .clearLiveImages();
                            _showSovereignNotification(
                              'Локальный кэш очищен',
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

              // 5. VERSION AT BOTTOM
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 32,
                      bottom: Dimens.gapXl,
                    ), // 24
                    child: Text(
                      "Версия $_appVersion",
                      style: GoogleFonts.inter(
                        color: colors.contentTertiary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
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
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(
          Dimens.radiusXl,
        ), // 18 approx -> 24 in system, sticking to 18 for specific visual
        border: Border.all(color: colors.divider),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Dimens.radiusXl),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(Dimens.paddingCard), // 16
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _updateProfilePicture(context, user.uid),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            colors.accentAction,
                            colors.accentAction.withValues(alpha: 0.6),
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
                          radius: 28,
                          backgroundColor: colors.surfaceContainer,
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: _isUploading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.accentAction,
                                  ),
                                )
                              : (user.photoUrl == null
                                    ? Icon(
                                        Icons.person_outline_rounded,
                                        size: 24,
                                        color: colors.neutralGray,
                                      )
                                    : null),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.accentAction,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.surfaceHigh,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimens.gapL), // 16
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? 'Пользователь' : user.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.contentPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.contentSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Dimens.gapS), // 8
                    InkWell(
                      onTap: () => _showEditSheet(
                        context,
                        'Ваше имя',
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
                              'Имя обновлено',
                              Icons.person_rounded,
                              colors.accentAction,
                              colors,
                            );
                          }
                        },
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Редактировать',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.contentPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, SkladColors colors) {
    // Use the updated provider name
    final created = ref.watch(userCreatedTasksProvider).asData?.value ?? 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildBigStatCard(
              'Статус',
              'Активен',
              Icons.verified_user_rounded,
              colors.success,
              colors,
            ),
          ),
          const SizedBox(width: Dimens.gapM), // 12
          Expanded(
            child: _buildBigStatCard(
              'Создано',
              '$created',
              Icons.assignment_add,
              colors.accentAction,
              colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigStatCard(
    String title,
    String value,
    IconData icon,
    Color accent,
    SkladColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(Dimens.paddingCard), // 16
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(Dimens.radiusXl), // 18
        border: Border.all(color: colors.divider),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(Dimens.gapS), // 8
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: Dimens.gapM), // 12
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.contentPrimary,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: colors.contentSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
        borderRadius: BorderRadius.circular(Dimens.radiusXl), // 18
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimens.gapS), // 8
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.contentSecondary, size: 18),
          ),
          const SizedBox(width: Dimens.gapL), // 16
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.contentPrimary,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: value,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                onChanged(v);
              },
              activeThumbColor: colors.accentAction,
              inactiveTrackColor: colors.surfaceContainer,
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimens.gapS), // 8
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colors.contentSecondary, size: 18),
              ),
              const SizedBox(width: Dimens.gapL), // 16
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.contentPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colors.contentSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.contentTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, SkladColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.contentTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDivider(SkladColors colors) {
    return Divider(height: 1, thickness: 1, indent: 56, color: colors.divider);
  }

  // ───────────────── BETTER SHEETS ─────────────────

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
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Dimens.radiusXl),
          ), // 24
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + Dimens.gapXl, // 24
          left: Dimens.gapXl, // 24
          right: Dimens.gapXl, // 24
          top: Dimens.gapM, // 12
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: Dimens.gapXl), // 24
                decoration: BoxDecoration(
                  color: colors.contentTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.accentAction.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: colors.accentAction,
                    size: 28,
                  ),
                ),
                const SizedBox(height: Dimens.gapL), // 16
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.contentPrimary,
                  ),
                ),
                const SizedBox(height: Dimens.gapS), // 8
                Text(
                  "Обновите информацию ниже",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.contentSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: colors.contentPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              keyboardType: isEmail
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              cursorColor: colors.accentAction,
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surfaceContainer,
                hintText: "Введите значение",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimens.radiusL), // 16
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimens.radiusL), // 16
                  borderSide: BorderSide(color: colors.accentAction, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // SIDE BY SIDE BUTTONS with Outlined Cancel
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      foregroundColor: colors.contentSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: colors.divider,
                          width: 1,
                        ), // Thin outline
                      ),
                    ),
                    child: Text(
                      'Отмена',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: Dimens.gapM), // 12
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onSave(controller.text.trim());
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      backgroundColor: colors.accentAction,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Сохранить',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Dimens.radiusXl),
          ), // 24
        ),
        padding: const EdgeInsets.all(Dimens.gapXl), // 24
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: Dimens.gapXl), // 24
              decoration: BoxDecoration(
                color: colors.contentTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
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

            const SizedBox(height: Dimens.gapL), // 16
            Text(
              "Сброс пароля",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.contentPrimary,
              ),
            ),
            const SizedBox(height: Dimens.gapM), // 12
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.inter(
                  color: colors.contentSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: "Мы отправим ссылку для сброса пароля на:\n",
                  ),
                  TextSpan(
                    text: email,
                    style: TextStyle(
                      color: colors.contentPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // SIDE BY SIDE BUTTONS with Outlined Cancel
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      foregroundColor: colors.contentSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: colors.divider,
                          width: 1,
                        ), // Thin outline
                      ),
                    ),
                    child: Text(
                      'Отмена',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: Dimens.gapM), // 12
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: email,
                        );

                        // Check if the bottom sheet context is still valid
                        if (!ctx.mounted) return;

                        // Use the specific context (ctx) to pop the sheet
                        Navigator.pop(ctx);

                        _showSovereignNotification(
                          'Письмо со сбросом пароля отправлено',
                          Icons.mail_outline_rounded,
                          colors.accentAction,
                          colors,
                        );
                      } catch (_) {
                        // Check ctx.mounted here as well
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      backgroundColor: colors.accentAction,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Отправить',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
      // FIX: Use the static method from the class
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
