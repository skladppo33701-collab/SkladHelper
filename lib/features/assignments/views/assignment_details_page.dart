import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// Core
import '../../../../core/theme.dart';
import '../../../../core/constants/dimens.dart';

// Features
import '../../auth/providers/auth_provider.dart';
import '../models/assignment_model.dart';
import '../providers/assignment_provider.dart';
import '../../inventory/presentation/scanner_page.dart';

class AssignmentDetailsPage extends ConsumerWidget {
  final String assignmentId;

  const AssignmentDetailsPage({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [PROTOCOL-VISUAL-1] Use extension for theme
    final colors = context.colors;

    // Получаем конкретное задание из состояния
    final assignment = ref
        .watch(assignmentsProvider)
        .firstWhere(
          (a) => a.id == assignmentId,
          orElse: () => Assignment(
            id: '',
            name: 'Не найдено',
            // Corrected: Provide required 'type' and remove undefined parameters
            type: 'unknown',
            // description: '', // Removed undefined parameter
            status: AssignmentStatus
                .created, // Corrected: Use 'created' instead of 'pending' if 'pending' doesn't exist
            createdAt: DateTime.now(),
            items: [],
            // createdBy: 'system', // Removed undefined parameter
          ),
        );

    final userAsync = ref.watch(userRoleProvider);
    final creatorPfp = userAsync.asData?.value?.photoUrl;

    if (assignment.id.isEmpty) {
      return Scaffold(
        backgroundColor: colors.surfaceLow,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Задание не найдено')),
      );
    }

    final totalItems = assignment.items.length;
    final scannedItems = assignment.items
        .where((i) => i.scannedQty >= i.requiredQty)
        .length;
    final progress = totalItems > 0 ? scannedItems / totalItems : 0.0;

    return Scaffold(
      backgroundColor: colors.surfaceLow,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. SOFT-TONE EXECUTIVE APP BAR
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: colors.surfaceLow,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colors.contentPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Кнопка меню "Три точки"
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors.contentPrimary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimens.radiusL), // 16
                ),
                color: colors.surfaceHigh,
                offset: const Offset(0, 40),
                onSelected: (value) {
                  if (value == 'complete') {
                    ref
                        .read(assignmentsProvider.notifier)
                        .completeAssignment(assignment.id);
                  } else if (value == 'info') {
                    _showInfoSheet(context, assignment, colors);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: colors.success,
                          size: 20,
                        ),
                        const SizedBox(width: Dimens.gapM), // 12
                        const Text('Завершить'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: colors.accentAction,
                          size: 20,
                        ),
                        const SizedBox(width: Dimens.gapM), // 12
                        const Text('Информация'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(
                horizontal: Dimens.gapXl, // 24
                vertical: Dimens.gapL, // 16
              ),
              background: Container(
                // [PROTOCOL-VISUAL-1] Use Dimens
                padding: const EdgeInsets.fromLTRB(
                  Dimens.gapXl,
                  60,
                  Dimens.gapXl,
                  Dimens.module,
                ),
                color: colors.surfaceContainer, // Мягкий фон
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatusBadge(assignment.status, colors),
                          const SizedBox(height: Dimens.gapS), // 8
                          Text(
                            assignment.name,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: colors.contentPrimary,
                              letterSpacing: -0.8,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Dimens.gapL), // 16
                    // Аватар создателя
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.divider, width: 1),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: colors.surfaceHigh,
                        backgroundImage:
                            (creatorPfp != null && creatorPfp.isNotEmpty)
                            ? NetworkImage(creatorPfp)
                            : null,
                        child: (creatorPfp == null || creatorPfp.isEmpty)
                            ? Text(
                                "M",
                                style: TextStyle(
                                  color: colors.accentAction,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
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

          // 2. PROGRESS SECTION
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimens.gapXl, // 24
                Dimens.gapL, // 16
                Dimens.gapXl, // 24
                0,
              ),
              child: _buildProgressSection(
                progress,
                scannedItems,
                totalItems,
                colors,
              ),
            ),
          ),

          // 3. ITEMS LIST HEADER
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Dimens.gapXl, // 24
              Dimens.module, // 20
              Dimens.gapXl, // 24
              Dimens.gapS, // 8
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ТОВАРЫ В СПИСКЕ',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: colors.contentTertiary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '$totalItems поз.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colors.contentSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. COMPACT ITEM CARDS
          if (assignment.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(colors),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.gapXl,
              ), // 24
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = assignment.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildCompactItemCard(
                      context,
                      ref,
                      assignment.id,
                      item,
                      colors,
                    ),
                  );
                }, childCount: assignment.items.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: _buildScannerFAB(context, colors),
    );
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildStatusBadge(AssignmentStatus status, SkladColors colors) {
    final isCompleted = status == AssignmentStatus.completed;
    final color = isCompleted ? colors.success : colors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        isCompleted ? 'ЗАВЕРШЕНО' : 'В ПРОЦЕССЕ',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    double progress,
    int scanned,
    int total,
    SkladColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(Dimens.paddingCard), // 16
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(Dimens.module), // 20
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Прогресс сборки',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.contentSecondary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  color: colors.accentAction,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colors.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accentAction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactItemCard(
    BuildContext context,
    WidgetRef ref,
    String assId,
    AssignmentItem item,
    SkladColors colors,
  ) {
    final isDone = item.scannedQty >= item.requiredQty;

    return Slidable(
      key: Key('${assId}_${item.code}'),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              ref
                  .read(assignmentsProvider.notifier)
                  .updateItemScan(
                    assId,
                    item.code,
                    increment: -item.scannedQty,
                  );
            },
            backgroundColor: colors.error,
            foregroundColor: Colors.white,
            icon: Icons.refresh_rounded,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(Dimens.radiusL), // 16
            ),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceHigh,
            borderRadius: BorderRadius.circular(Dimens.radiusL), // 16
            border: Border.all(
              color: isDone
                  ? colors.success.withValues(alpha: 0.3)
                  : colors.divider,
              width: isDone ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimens.radiusL),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 3,
                    color: isDone ? colors.success : colors.divider,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.gapM, // 12
                        vertical: Dimens.gapS, // 8
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: colors.contentPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDone)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: colors.success,
                                  size: 16,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.code,
                                  // Corrected: Use 'jetBrainsMono' (case-sensitive)
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: colors.contentSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "План: ${item.requiredQty.toInt()}",
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: colors.accentAction.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              _buildCompactStepper(ref, assId, item, colors),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildCompactStepper(
    WidgetRef ref,
    String assId,
    AssignmentItem item,
    SkladColors colors,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniStepperButton(
            icon: Icons.remove_rounded,
            onTap: () {
              if (item.scannedQty <= 0) return;
              HapticFeedback.lightImpact();
              ref
                  .read(assignmentsProvider.notifier)
                  .updateItemScan(assId, item.code, increment: -1.0);
            },
            colors: colors,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            child: Text(
              item.scannedQty.toStringAsFixed(0),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: colors.contentPrimary,
              ),
            ),
          ),
          _miniStepperButton(
            icon: Icons.add_rounded,
            onTap: () {
              if (item.scannedQty >= item.requiredQty) return;
              HapticFeedback.mediumImpact();
              ref
                  .read(assignmentsProvider.notifier)
                  .updateItemScan(assId, item.code, increment: 1.0);
            },
            colors: colors,
            isAdd: true,
          ),
        ],
      ),
    );
  }

  Widget _miniStepperButton({
    required IconData icon,
    required VoidCallback onTap,
    required SkladColors colors,
    bool isAdd = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 14,
          color: isAdd ? colors.accentAction : colors.contentTertiary,
        ),
      ),
    );
  }

  void _showInfoSheet(
    BuildContext context,
    Assignment ass,
    SkladColors colors,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colors.surfaceHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(Dimens.gapXl), // 24
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Dimens.gapXl), // 24
            Text(
              "Сведения о заказе",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.contentPrimary,
              ),
            ),
            const SizedBox(height: Dimens.module), // 20
            // Используем динамические данные из модели с нейтральными заглушками
            _buildInfoRow(
              "Документ основание",
              ass.documentBase ?? "Не указано",
              colors,
            ),
            _buildInfoRow("Отправитель", ass.sender ?? "Не указано", colors),
            _buildInfoRow("Получатель", ass.receiver ?? "Не указано", colors),
            const SizedBox(height: Dimens.gapL), // 16
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentAction,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimens.radiusM), // 12
                  ),
                  elevation: 0,
                ),
                child: const Text("Понятно"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, SkladColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.contentTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colors.contentPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerFAB(BuildContext context, SkladColors colors) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.heavyImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScannerPage()),
        );
      },
      backgroundColor: colors.accentAction,
      icon: const Icon(
        Icons.qr_code_scanner_rounded,
        color: Colors.white,
        size: 20,
      ),
      label: Text(
        'СКАНЕР',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimens.radiusL), // 16
      ),
    );
  }

  Widget _buildEmptyState(SkladColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_rounded,
            size: 64,
            color: colors.contentTertiary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Список пуст',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.contentPrimary.withValues(alpha: 0.8),
            ),
          ),
          Text(
            'Товары не найдены',
            style: TextStyle(
              color: colors.contentSecondary.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
