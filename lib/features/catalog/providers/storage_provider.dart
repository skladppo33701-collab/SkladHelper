import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../models/product_model.dart';

// -----------------------------------------------------------------------------
// MIGRATED: Uses 'Notifier' instead of 'StateNotifier' (Riverpod 2.0/3.0 Standard)
// -----------------------------------------------------------------------------
class StorageNotifier extends Notifier<List<Product>> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  @override
  List<Product> build() {
    // 1. Initialize with empty list
    // 2. Trigger load from disk (fire-and-forget)
    _loadFromDisk();
    return [];
  }

  // 1. Load Database
  Future<void> _loadFromDisk() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/master_db.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);

        // Update state
        state = jsonList.map((e) => Product.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("DB Load Error: $e");
    }
  }

  // 2. Save Database
  Future<void> _saveToDisk() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/master_db.json');
      final jsonString = jsonEncode(state.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint("DB Save Error: $e");
    }
  }

  // 3. Import Excel
  Future<int> importExcel(List<int> bytes) async {
    _isLoading = true;
    // Notify listeners (optional, handled by UI spinner usually)
    // In Notifier, we just update state.
    // If you wanted to expose loading state, you'd use AsyncNotifier,
    // but for now we keep it simple.

    final List<Product> newProducts = [];

    String currentStorage = 'Не определен';
    String currentCategory = 'Общее';

    final storageMarkers = [
      '33701_0090',
      '33701_0091',
      '33701_0095',
      '33701_0097',
      '33701_0098',
      '33701_0200',
      'Hi Technic',
    ];

    void processRows(List<List<dynamic>> rows) {
      for (var row in rows) {
        final rowStr = row.map((e) => e?.toString().trim() ?? '').toList();

        if (rowStr.every((element) => element.isEmpty)) continue;
        if (rowStr.length < 2) continue;

        final col0 = rowStr[0];
        final col1 = rowStr.length > 1 ? rowStr[1] : '';

        // A. Storage Header
        bool isStorageHeader = storageMarkers.any(
          (marker) => col0.contains(marker),
        );
        if (col1.isEmpty && isStorageHeader) {
          currentStorage = col0;
          currentCategory = '';
          continue;
        }

        // B. Category Header
        if (col1.isEmpty &&
            col0.isNotEmpty &&
            !isStorageHeader &&
            !col0.contains('Показатели') &&
            !col0.contains('Ведомость') &&
            !col0.contains('Итого')) {
          currentCategory = col0;
          continue;
        }

        // C. Product Item
        if (col0.isNotEmpty && RegExp(r'^[0-9]+(\.0)?$').hasMatch(col1)) {
          String cleanCode = col1.replaceAll(RegExp(r'\.0$'), '');

          double qty = 0.0;
          if (rowStr.length > 2) {
            String qStr = rowStr[2]
                .replaceAll(RegExp(r'\s+'), '')
                .replaceAll(',', '.');
            qty = double.tryParse(qStr) ?? 0.0;
          }

          newProducts.add(
            Product(
              code: cleanCode,
              name: col0,
              category: currentCategory,
              storage: currentStorage,
              quantity: qty,
            ),
          );
        }
      }
    }

    try {
      // Try Excel
      try {
        var decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
        for (var table in decoder.tables.values) {
          processRows(table.rows);
        }
      } catch (e) {
        // Try CSV
        final content = utf8.decode(bytes, allowMalformed: true);
        final lines = const LineSplitter().convert(content);
        final rows = lines
            .map((l) => l.split(l.contains(';') ? ';' : ','))
            .toList();
        processRows(rows);
      }

      if (newProducts.isNotEmpty) {
        state = newProducts;
        await _saveToDisk();
      }
      return newProducts.length;
    } catch (e) {
      debugPrint("Import Error: $e");
      return 0;
    } finally {
      _isLoading = false;
    }
  }

  // 4. Search Logic
  List<Product> search(String query) {
    if (query.isEmpty) return state;
    final lower = query.toLowerCase();

    return state.where((p) {
      return p.name.toLowerCase().contains(lower) ||
          p.code.contains(lower) ||
          p.storage.toLowerCase().contains(lower) ||
          p.category.toLowerCase().contains(lower);
    }).toList();
  }
}

// -----------------------------------------------------------------------------
// UPDATED PROVIDER DEFINITION (NotifierProvider instead of StateNotifierProvider)
// -----------------------------------------------------------------------------
final storageProvider = NotifierProvider<StorageNotifier, List<Product>>(() {
  return StorageNotifier();
});
