import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Core
import '../../../../core/theme.dart';
import '../../../../core/constants/dimens.dart';

// Features
import '../models/product_model.dart';
import '../providers/storage_provider.dart';

class StoragePage extends ConsumerStatefulWidget {
  const StoragePage({super.key});

  @override
  ConsumerState<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends ConsumerState<StoragePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isDragging = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDrop(List<XFile> files) async {
    if (files.isEmpty) return;
    final colors = context.colors;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Обновление базы... Подождите',
          style: GoogleFonts.inter(color: colors.contentPrimary),
        ),
        backgroundColor: colors.surfaceHigh,
      ),
    );

    try {
      final file = files.first;
      final bytes = await file.readAsBytes();
      final count = await ref.read(storageProvider.notifier).importExcel(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Готово! Загружено товаров: $count',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: colors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimens.radiusM),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimens.radiusM),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // [PROTOCOL-VISUAL-1] Sovereign Theme Access
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allProducts = ref.watch(storageProvider);
    final displayList = ref.read(storageProvider.notifier).search(_searchQuery);

    return Scaffold(
      backgroundColor: colors.surfaceLow,
      body: DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: (details) => _handleDrop(details.files),
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. APP BAR & SEARCH
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  backgroundColor: colors.surfaceLow.withValues(alpha: 0.95),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  expandedHeight: 140,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.gapXl, // 24
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'База товаров',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colors.contentPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimens.gapS, // 8
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.accentAction.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    Dimens.radiusM,
                                  ), // 12
                                ),
                                child: Text(
                                  '${allProducts.length} SKU',
                                  style: GoogleFonts.inter(
                                    color: colors.accentAction,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.gapL), // 16
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            style: GoogleFonts.inter(
                              color: colors.contentPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Поиск (Код, Название, Склад)...',
                              hintStyle: GoogleFonts.inter(
                                color: colors.contentTertiary,
                              ),
                              prefixIcon: Icon(
                                LucideIcons.search,
                                color: colors.neutralGray,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: colors.surfaceHigh,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimens.radiusL,
                                ), // 16
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: Dimens.gapL,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimens.gapL), // 16
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. PRODUCT LIST
                displayList.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(
                          colors,
                          _searchQuery.isNotEmpty,
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimens.gapXl, // 24
                          vertical: Dimens.gapM, // 12
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final product = displayList[index];
                            return _buildProductCard(product, colors, isDark);
                          }, childCount: displayList.length),
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),

            // DRAG OVERLAY
            if (_isDragging)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.save, // Replaced save_alt
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: Dimens.gapXl),
                      Text(
                        "Отпустите файл 'Остатки'",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper: Storage Badge with Theme Colors
  Widget _buildStorageBadge(String fullStorageName, SkladColors colors) {
    String label = 'Склад';
    Color badgeColor = colors.neutralGray;

    if (fullStorageName.contains('0090')) {
      label = 'Основной (0090)';
      badgeColor = Colors.blue;
    } else if (fullStorageName.contains('0091')) {
      label = 'Уценка (0091)';
      badgeColor = Colors.orange;
    } else if (fullStorageName.contains('Hi Technic') ||
        fullStorageName.contains('0095')) {
      label = 'Hi Technic (0095)';
      badgeColor = Colors.purple;
    } else if (fullStorageName.contains('0097')) {
      label = 'Возврат (0097)';
      badgeColor = colors.error; // Red
    } else if (fullStorageName.contains('0098')) {
      label = 'Претензия (0098)';
      badgeColor = Colors.deepOrange;
    } else if (fullStorageName.contains('0200')) {
      label = 'В пути (0200)';
      badgeColor = colors.success; // Teal/Green
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimens.radiusS), // 8
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, SkladColors colors, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimens.gapM), // 12
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(Dimens.radiusL), // 16
        border: Border.all(color: colors.divider),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimens.paddingCard), // 16
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colors.contentPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimens.gapS), // 8
                  Row(
                    children: [
                      // Code Badge
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
                          product.code,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.contentSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimens.gapM), // 12
                      // Category
                      if (product.category.isNotEmpty)
                        Flexible(
                          child: Text(
                            product.category,
                            style: GoogleFonts.inter(
                              color: colors.contentTertiary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (product.storage.isNotEmpty)
                    _buildStorageBadge(product.storage, colors),
                ],
              ),
            ),
            const SizedBox(width: Dimens.gapL), // 16
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.quantity.toStringAsFixed(0),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: product.quantity > 0 ? colors.success : colors.error,
                  ),
                ),
                Text(
                  "шт",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colors.contentTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(SkladColors colors, bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? LucideIcons.searchX : LucideIcons.packageOpen,
            size: 64,
            color: colors.neutralGray.withValues(alpha: 0.3),
          ),
          const SizedBox(height: Dimens.gapL),
          Text(
            isSearch ? 'Ничего не найдено' : 'База пуста',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.contentSecondary,
            ),
          ),
          if (!isSearch)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Перетащите файл "Остатки.xls" сюда',
                style: GoogleFonts.inter(
                  color: colors.contentTertiary,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
