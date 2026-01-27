import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cross_file/cross_file.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
// [PROTOCOL-VISUAL-1] Professional Icon Set
import 'package:lucide_icons/lucide_icons.dart';

// Core & Theme
import '../../../../core/theme.dart';
import '../../../../core/constants/dimens.dart';
// If this import path is correct, UploadHelper should be visible.
import '../../../../core/utils/upload/upload_helper.dart';

// Features
import '../../auth/providers/auth_provider.dart';
import '../../assignments/models/assignment_model.dart';
import '../../assignments/providers/assignment_provider.dart';
import '../../assignments/services/assignment_parser.dart';
import '../../assignments/views/assignment_details_page.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All';
  bool _isDragging = false;
  bool _isProcessingDrop = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSovereignNotification(
    String message,
    IconData icon,
    Color accentColor,
  ) {
    if (!mounted) return;
    final colors = context.colors;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.paddingCard,
            vertical: Dimens.gapM,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceHigh.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(Dimens.radiusL),
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
                padding: const EdgeInsets.all(Dimens.gapS),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: Dimens.gapM),
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

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    if (files.isEmpty) return;
    final colors = context.colors;

    setState(() => _isProcessingDrop = true);
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();

        // [PROTOCOL-ARCH-2] Use Isolate for parsing to prevent UI freeze
        final result = await AssignmentParser.parseExcelIsolate(
          bytes,
          file.name,
        );

        result.fold(
          (failure) {
            _showSovereignNotification(
              failure.message,
              LucideIcons.alertCircle,
              colors.error,
            );
          },
          (assignment) {
            ref.read(assignmentsProvider.notifier).addAssignment(assignment);
            _showSovereignNotification(
              'Задание создано',
              LucideIcons.checkCircle,
              colors.success,
            );
          },
        );
      } catch (e) {
        // Fallback catch for unexpected errors outside the Result pattern
        _showSovereignNotification(
          'Системная ошибка: $e',
          LucideIcons.alertCircle,
          colors.error,
        );
      }
    }
    if (mounted) setState(() => _isProcessingDrop = false);
  }

  Future<void> _pickFileFromDevice() async {
    try {
      // Using the helper to pick a single file (XFile)
      final file = await UploadHelper.pickFile();
      if (file != null) {
        // Reuse the drop handler logic
        await _handleDroppedFiles([file]);
      }
    } catch (e) {
      if (mounted) {
        _showSovereignNotification(
          'Ошибка выбора файла: $e',
          LucideIcons.alertCircle,
          context.colors.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacings = context.spacings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allAssignments = ref.watch(assignmentsProvider);
    final filteredAssignments = allAssignments.where((a) {
      final matchesSearch = a.name.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
      if (!matchesSearch) return false;
      if (_filterStatus == 'Active') {
        return a.status != AssignmentStatus.completed;
      }
      if (_filterStatus == 'Completed') {
        return a.status == AssignmentStatus.completed;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: colors.surfaceLow,
      body: DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: (detail) => _handleDroppedFiles(detail.files),
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    // [PROTOCOL-VISUAL-1] Standardized Padding
                    padding: const EdgeInsets.fromLTRB(
                      Dimens.gapXl,
                      Dimens.gapXl,
                      Dimens.gapXl,
                      Dimens.gapS,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Задания',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: colors.contentPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            // [Mobile Upload] Add Button for manual upload
                            IconButton(
                              onPressed: _pickFileFromDevice,
                              icon: Icon(
                                LucideIcons.uploadCloud,
                                color: colors.accentAction,
                                size: 24,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: colors.accentAction.withValues(
                                  alpha: 0.1,
                                ),
                                padding: const EdgeInsets.all(Dimens.gapS),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    Dimens.radiusM,
                                  ),
                                ),
                              ),
                              tooltip: 'Загрузить файл',
                            ),
                          ],
                        ),
                        SizedBox(height: spacings.module), // 20.0
                        _buildStatsRow(allAssignments, colors, spacings),
                        SizedBox(height: spacings.module),
                        _buildSearchBar(colors),
                      ],
                    ),
                  ),
                ),
                _buildStickyFilters(colors),
                _buildAssignmentList(filteredAssignments, colors),
              ],
            ),
            if (_isDragging || _isProcessingDrop)
              _buildDropOverlay(isDark, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    List<Assignment> all,
    SkladColors colors,
    SkladSpacings spacings,
  ) {
    // [PROTOCOL-VISUAL-2] Reflow Hardening: Replaced fixed height with IntrinsicHeight
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _buildBentoCard(
              colors: colors,
              title: 'В работе',
              value: all
                  .where((a) => a.status != AssignmentStatus.completed)
                  .length
                  .toString(),
              icon: LucideIcons.timer,
              accent: colors.warning,
              isHero: true,
            ),
          ),
          SizedBox(width: spacings.m), // 12.0
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildBentoCard(
                  colors: colors,
                  title: 'Всего',
                  value: all.length.toString(),
                  icon: LucideIcons.folder,
                  accent: colors.contentSecondary,
                  isSmall: true,
                ),
                SizedBox(height: spacings.m),
                _buildBentoCard(
                  colors: colors,
                  title: 'Товаров',
                  value: all
                      .fold(0, (sum, a) => sum + a.items.length)
                      .toString(),
                  icon: LucideIcons.package,
                  accent: colors.accentAction,
                  isSmall: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(SkladColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingCard),
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(Dimens.radiusL),
        border: Border.all(color: colors.divider),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(color: colors.contentPrimary, fontSize: 15),
        onChanged: (v) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Поиск...',
          hintStyle: GoogleFonts.inter(color: colors.contentTertiary),
          icon: Icon(
            LucideIcons.search,
            color: colors.contentSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStickyFilters(SkladColors colors) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyFilterDelegate(
        child: Container(
          height: 56,
          color: colors.surfaceLow.withValues(alpha: 0.98),
          padding: const EdgeInsets.symmetric(horizontal: Dimens.gapXl),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              _buildFilterChip(colors, 'All', 'Все'),
              const SizedBox(width: Dimens.gapS),
              _buildFilterChip(colors, 'Active', 'В работе'),
              const SizedBox(width: Dimens.gapS),
              _buildFilterChip(colors, 'Completed', 'Завершенные'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentList(
    List<Assignment> assignments,
    SkladColors colors,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.gapXl,
        Dimens.gapS,
        Dimens.gapXl,
        100,
      ),
      sliver: SliverToBoxAdapter(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: assignments.isEmpty
              ? _buildEmptyState(colors)
              : ListView.builder(
                  key: ValueKey("${_filterStatus}_${assignments.length}"),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assignments.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _buildSovereignSlidable(assignments[i], colors),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSovereignSlidable(Assignment ass, SkladColors colors) {
    final userAsync = ref.watch(userRoleProvider);
    final creatorPfp = userAsync.asData?.value?.photoUrl;
    final isCompleted = ass.status == AssignmentStatus.completed;

    return Slidable(
      key: Key(ass.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              ref.read(assignmentsProvider.notifier).deleteAssignment(ass.id);
              _showSovereignNotification(
                'Задание удалено',
                LucideIcons.trash2,
                colors.error,
              );
            },
            backgroundColor: colors.error,
            foregroundColor: Colors.white,
            icon: LucideIcons.trash2,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(Dimens.module),
            ),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => AssignmentDetailsPage(assignmentId: ass.id),
            ),
          ),
          borderRadius: BorderRadius.circular(Dimens.module),
          child: Ink(
            padding: const EdgeInsets.all(Dimens.paddingCard),
            decoration: BoxDecoration(
              color: colors.surfaceHigh,
              borderRadius: BorderRadius.circular(Dimens.module),
              border: Border.all(color: colors.divider),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    // Remove fixed height to allow stretch
                    decoration: BoxDecoration(
                      color: isCompleted ? colors.success : colors.warning,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: Dimens.gapL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ass.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: colors.contentPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.package,
                              size: 14,
                              color: colors.contentTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${ass.items.length} поз.",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colors.contentSecondary,
                              ),
                            ),
                            const SizedBox(width: Dimens.gapM),
                            Icon(
                              LucideIcons.clock,
                              size: 14,
                              color: colors.contentTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('HH:mm').format(ass.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colors.contentSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: Dimens.module,
                      backgroundColor: colors.accentAction.withValues(
                        alpha: 0.1,
                      ),
                      backgroundImage:
                          (creatorPfp != null && creatorPfp.isNotEmpty)
                          ? NetworkImage(creatorPfp)
                          : null,
                      child: (creatorPfp == null || creatorPfp.isEmpty)
                          ? Text(
                              "М",
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.accentAction,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required SkladColors colors,
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    bool isSmall = false,
    bool isHero = false,
  }) {
    // [PROTOCOL-VISUAL-2]: Min height ensures touch targets are accessible
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(Dimens.module),
        border: Border.all(color: colors.divider),
      ),
      child: isSmall
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: Dimens.gapM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.contentPrimary,
                          ),
                        ),
                      ),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: colors.contentSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 24, color: accent),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      child: Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: colors.contentPrimary,
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.contentSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(SkladColors colors, String value, String label) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filterStatus = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentAction : colors.surfaceHigh,
          borderRadius: BorderRadius.circular(Dimens.radiusM),
          border: Border.all(
            color: isSelected ? colors.accentAction : colors.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : colors.contentSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(SkladColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Icon(
              LucideIcons.cloudOff,
              size: 80,
              color: colors.contentTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Dimens.gapL),
            Text(
              'Нет заданий',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.contentPrimary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Перетащите .xlsx файл',
              style: TextStyle(
                color: colors.contentSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropOverlay(bool isDark, SkladColors colors) {
    return Container(
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.download, size: 72, color: colors.accentAction),
            const SizedBox(height: Dimens.gapL),
            Text(
              'Отпустите файл',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.accentAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyFilterDelegate({required this.child});
  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;
  @override
  Widget build(ctx, offset, overlaps) =>
      Material(elevation: overlaps ? 4 : 0, child: child);
  @override
  bool shouldRebuild(_StickyFilterDelegate old) => true;
}
