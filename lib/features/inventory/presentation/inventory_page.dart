import 'package:flutter/material.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine if we are currently in dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Adaptive Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchBar(
                hintText: 'Поиск бытовой техники...',
                hintStyle: WidgetStatePropertyAll(
                  TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
                ),
                leading: const Icon(Icons.search, color: Colors.grey),
                trailing: [
                  IconButton(
                    icon: Icon(
                      Icons.qr_code_scanner,
                      // Use theme primary color instead of hardcoded dark blue
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      // Logic for Barcode Scanning
                    },
                  ),
                ],
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(
                          alpha: 0.05,
                        ), // Subtle grey for light mode
                ),
              ),
            ),

            // 2. Result Cards
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) => _buildResultCard(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // FIX: Use Surface color from theme or white for light mode
      color: isDark ? const Color(0xFF111827) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // FIX: Use darker border for light mode to maintain definition
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          'Стиральная машина Samsung V2',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            // FIX: Ensure text is readable in both modes
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Артикул: 7701-4432',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              'Категория: СМА (Стир. машины)',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
