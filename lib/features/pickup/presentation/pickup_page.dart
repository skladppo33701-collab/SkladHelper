import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sklad_helper_33701/core/theme.dart';
import 'package:sklad_helper_33701/core/constants/dimens.dart'; // [PROTOCOL-VISUAL-1]

class PickUpPage extends ConsumerStatefulWidget {
  const PickUpPage({super.key});

  @override
  ConsumerState<PickUpPage> createState() => _PickUpPageState();
}

class _PickUpPageState extends ConsumerState<PickUpPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: All, 1: Pending, 2: Ready

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SkladColors>()!;

    return Scaffold(
      backgroundColor: colors.surfaceLow,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Executive Header
          SliverToBoxAdapter(
            child: Container(
              // [PROTOCOL-VISUAL-1] Tokenized Padding
              padding: const EdgeInsets.fromLTRB(
                Dimens.gapXl,
                60,
                Dimens.gapXl,
                Dimens.module,
              ),
              color: colors.surfaceContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Отгрузка & Выдача",
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: colors.contentPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "Управление исходящими потоками",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: colors.contentSecondary,
                            ),
                          ),
                        ],
                      ),
                      _buildScanButton(colors),
                    ],
                  ),
                  const SizedBox(height: Dimens.gapXl),
                  _buildSearchBar(colors),
                ],
              ),
            ),
          ),

          // Statistics Overview
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Dimens.gapXl,
              Dimens.module,
              Dimens.gapXl,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: IntrinsicHeight(
                // [PROTOCOL-VISUAL-2] Intrinsic height ensures tiles match size
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatTile("Ожидают", "12", colors.warning, colors),
                    const SizedBox(width: Dimens.gapM),
                    _buildStatTile("Готовы", "08", colors.success, colors),
                    const SizedBox(width: Dimens.gapM),
                    _buildStatTile("Задержка", "02", colors.error, colors),
                  ],
                ),
              ),
            ),
          ),

          // Filter Tabs
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Dimens.gapXl,
              Dimens.gapXl,
              Dimens.gapXl,
              Dimens.gapM,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  _buildFilterChip(0, "Все заказы"),
                  const SizedBox(width: Dimens.gapS),
                  _buildFilterChip(1, "Сборка"),
                  const SizedBox(width: Dimens.gapS),
                  _buildFilterChip(2, "Выдача"),
                ],
              ),
            ),
          ),

          // Main List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pickups')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(colors));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Dimens.gapXl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPickupCard(docs[index], colors),
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    Color accent,
    SkladColors colors,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(Dimens.gapL),
        decoration: BoxDecoration(
          color: colors.surfaceHigh,
          borderRadius: BorderRadius.circular(Dimens.radiusL),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.contentPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: colors.contentSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final colors = Theme.of(context).extension<SkladColors>()!;
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.gapL,
          vertical: Dimens.gapS,
        ),
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
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : colors.contentSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPickupCard(DocumentSnapshot doc, SkladColors colors) {
    final data = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: Dimens.gapM),
      padding: const EdgeInsets.all(Dimens.gapL),
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(Dimens.module),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Заказ #${data['orderId'] ?? '---'}",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    data['clientName'] ?? 'Частный клиент',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.contentSecondary,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(data['status'] ?? 'pending', colors),
            ],
          ),
          const SizedBox(height: Dimens.gapL),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: colors.contentTertiary,
              ),
              const SizedBox(width: Dimens.gapXs),
              Text(
                "Дедлайн: Сегодня, 18:00",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: colors.contentTertiary,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentAction,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimens.radiusM),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.gapL,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text(
                  "Выдать",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, SkladColors colors) {
    Color color = colors.warning;
    String label = "В сборке";
    if (status == 'ready') {
      color = colors.success;
      label = "Готов";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimens.radiusS),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildScanButton(SkladColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.accentAction,
        borderRadius: BorderRadius.circular(Dimens.radiusM),
      ),
      child: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar(SkladColors colors) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Поиск по номеру заказа или клиенту...",
        hintStyle: TextStyle(color: colors.contentTertiary, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: colors.contentTertiary),
        filled: true,
        fillColor: colors.surfaceLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusL),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState(SkladColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: colors.contentTertiary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: Dimens.gapL),
          Text(
            "Нет активных отгрузок",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: colors.contentSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
