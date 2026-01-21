import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sklad_helper_33701/core/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
// REMOVED: import 'dart:convert'; (Unused)
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();

  Future<void> _pickAndLoadCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'xls'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String csvContent = await file.readAsString();

        // Logic doesn't need context, so it's safe here
        ref.read(inventoryProvider.notifier).parseCsvData(csvContent);
      }
    } catch (e) {
      // FIX: Check if widget is still in the tree before using context
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryProvider);
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: proColors.surfaceLow,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER & SEARCH
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: proColors.surfaceHigh,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Складской учет",
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: _pickAndLoadCsv,
                        icon: Icon(
                          Icons.upload_file,
                          color: proColors.accentAction,
                        ),
                        tooltip: "Загрузить отчет 1С",
                        style: IconButton.styleFrom(
                          backgroundColor: proColors.accentAction.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        ref.read(inventoryProvider.notifier).search(val),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Поиск товара, артикула...',
                      hintStyle: TextStyle(color: proColors.neutralGray),
                      prefixIcon: Icon(
                        Icons.search,
                        color: proColors.neutralGray,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.qr_code_scanner,
                          color: proColors.accentAction,
                        ),
                        onPressed: () {
                          // TODO: Connect QR Scanner logic here
                        },
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. STATISTICS / FILTER CHIPS
            if (invState.allItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      "Всего: ${invState.filteredItems.length} поз.",
                      style: TextStyle(
                        color: proColors.neutralGray,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.filter_list,
                      size: 16,
                      color: proColors.neutralGray,
                    ),
                  ],
                ),
              ),

            // 3. LIST OF ITEMS
            Expanded(
              child: invState.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: proColors.accentAction,
                      ),
                    )
                  : invState.allItems.isEmpty
                  ? _buildEmptyState(proColors, isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: invState.filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = invState.filteredItems[index];
                        return _buildInventoryCard(item, proColors, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(SkladColors proColors, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: proColors.neutralGray.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Нет данных",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickAndLoadCsv,
            icon: const Icon(Icons.upload_file),
            label: const Text("Загрузить файл 1С (.csv)"),
            style: TextButton.styleFrom(
              foregroundColor: proColors.accentAction,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(
    InventoryItem item,
    SkladColors proColors,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: proColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: proColors.accentAction.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.brand.toUpperCase(),
                    style: TextStyle(
                      color: proColors.accentAction,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "${item.quantity.toStringAsFixed(0)} шт.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: item.quantity > 0
                        ? (isDark ? Colors.white : Colors.black87)
                        : proColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.qr_code, size: 14, color: proColors.neutralGray),
                const SizedBox(width: 4),
                Text(
                  item.sku,
                  style: TextStyle(color: proColors.neutralGray, fontSize: 12),
                ),
                const Spacer(),
                Icon(
                  Icons.warehouse_outlined,
                  size: 14,
                  color: proColors.neutralGray,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    item.warehouse,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: proColors.neutralGray,
                      fontSize: 12,
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
}
