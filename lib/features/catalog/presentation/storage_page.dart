import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sklad_helper_33701/core/theme.dart';
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Обновление базы... Подождите')),
    );

    try {
      final file = files.first;
      final bytes = await file.readAsBytes();
      final count = await ref.read(storageProvider.notifier).importExcel(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Готово! Загружено товаров: $count'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SkladColors>()!;
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
            Column(
              children: [
                // ЗАГОЛОВОК
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colors.surfaceHigh,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
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
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accentAction.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${allProducts.length} SKU',
                                style: TextStyle(
                                  color: colors.accentAction,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Поиск (Код, Название, Склад)...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: colors.neutralGray,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // СПИСОК
                Expanded(
                  child: displayList.isEmpty
                      ? _buildEmptyState(colors, _searchQuery.isNotEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final product = displayList[index];
                            return _buildProductCard(product, colors, isDark);
                          },
                        ),
                ),
              ],
            ),

            if (_isDragging)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save_alt, size: 80, color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        "Отпустите файл 'Остатки'",
                        style: TextStyle(color: Colors.white, fontSize: 18),
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

  // Форматирование длинных названий складов в короткие бейджи
  Widget _buildStorageBadge(String fullStorageName, SkladColors colors) {
    String label = 'Склад';
    Color color = colors.neutralGray;

    if (fullStorageName.contains('0090')) {
      label = 'Основной (0090)';
      color = Colors.blue;
    } else if (fullStorageName.contains('0091')) {
      label = 'Уценка (0091)';
      color = Colors.orange;
    } else if (fullStorageName.contains('Hi Technic') ||
        fullStorageName.contains('0095')) {
      label = 'Hi Technic (0095)';
      color = Colors.purple;
    } else if (fullStorageName.contains('0097')) {
      label = 'Возврат (0097)';
      color = Colors.redAccent;
    } else if (fullStorageName.contains('0098')) {
      label = 'Претензия (0098)';
      color = Colors.deepOrange;
    } else if (fullStorageName.contains('0200')) {
      label = 'В пути (0200)';
      color = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _buildProductCard(Product product, SkladColors colors, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                // Код товара
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.code,
                    style: TextStyle(
                      fontFamily: 'Monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Категория (Бренд)
                if (product.category.isNotEmpty)
                  Text(
                    product.category,
                    style: TextStyle(color: colors.neutralGray, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Склад (Бейдж)
            if (product.storage.isNotEmpty)
              _buildStorageBadge(product.storage, colors),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              product.quantity.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: product.quantity > 0 ? colors.success : colors.error,
              ),
            ),
            Text(
              "шт",
              style: TextStyle(fontSize: 10, color: colors.neutralGray),
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
            isSearch ? Icons.search_off : Icons.inventory_2_outlined,
            size: 64,
            color: colors.neutralGray.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'Ничего не найдено' : 'База пуста',
            style: TextStyle(fontSize: 18, color: colors.neutralGray),
          ),
          if (!isSearch)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Перетащите файл "Остатки.xls" сюда',
                style: TextStyle(color: colors.neutralGray),
              ),
            ),
        ],
      ),
    );
  }
}
