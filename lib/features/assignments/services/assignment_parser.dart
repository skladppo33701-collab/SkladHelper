import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For compute
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:uuid/uuid.dart';
import 'package:sklad_helper_33701/features/assignments/models/assignment_model.dart';
import 'package:sklad_helper_33701/core/utils/result.dart'; // [PROTOCOL-ARCH-1]

class AssignmentParser {
  /// [PROTOCOL-ARCH-2] Background Isolate Offloading
  /// Runs the heavy parsing logic in a separate isolate to prevent UI freeze.
  static Future<Result<Assignment, AppFailure>> parseExcelIsolate(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      // Offload to background thread
      final assignment = await compute(
        _parseExcelInternal,
        _ParseArgs(bytes, fileName),
      );
      return Success(assignment);
    } catch (e) {
      return Failure(ParsingFailure("Ошибка разбора файла: ${e.toString()}"));
    }
  }

  /// Internal method run by the isolate. Must be static or top-level.
  static Assignment _parseExcelInternal(_ParseArgs args) {
    final List<AssignmentItem> items = [];
    String docTitle = args.fileName.split('.').first;

    try {
      // Decode the spreadsheet bytes
      var decoder = SpreadsheetDecoder.decodeBytes(args.bytes, update: true);

      for (var table in decoder.tables.keys) {
        final rows = decoder.tables[table]!.rows;
        bool headerFound = false;
        int colSku = -1, colName = -1, colQty = -1;

        for (var row in rows) {
          final rowStr = row.map((e) => e?.toString().trim() ?? '').toList();

          // 1. Semantic Header Detection Logic
          if (!headerFound) {
            final lower = rowStr.map((e) => e.toLowerCase()).toList();
            for (int i = 0; i < lower.length; i++) {
              if (lower[i].contains('артикул') || lower[i] == 'код') {
                colSku = i;
              }
              if (lower[i].contains('товар') ||
                  lower[i].contains('номенклатура')) {
                colName = i;
              }
              if (lower[i] == 'количество' || lower[i] == 'кол-во') {
                colQty = i;
              }
            }
            if (colSku != -1 && colName != -1) {
              headerFound = true;
            }
            continue;
          }

          // 2. Data Extraction
          if (headerFound && colSku < row.length && colName < row.length) {
            final sku = rowStr[colSku];
            final name = rowStr[colName];
            if (sku.isEmpty || name.isEmpty) {
              continue;
            }

            double qty = 1.0;
            if (colQty != -1 && colQty < row.length) {
              String q = rowStr[colQty]
                  .replaceAll(RegExp(r'\s+'), '')
                  .replaceAll(',', '.');
              qty = double.tryParse(q) ?? 0.0;
            }

            if (qty > 0) {
              items.add(
                AssignmentItem(name: name, code: sku, requiredQty: qty),
              );
            }
          }
        }
      }

      if (items.isEmpty) {
        throw Exception(
          "Товары не найдены. Проверьте заголовки (Артикул, Товар).",
        );
      }

      // 3. Construct the full model object
      return Assignment(
        id: const Uuid().v4(),
        name: docTitle,
        type: 'Накладная',
        status: AssignmentStatus.inProgress,
        createdAt: DateTime.now(),
        items: items,
      );
    } catch (e) {
      // Re-throw to be caught by compute()'s error handling
      throw Exception("Invalid Excel format: $e");
    }
  }

  /// Extracts data from raw text (e.g., from PDF or Scans)
  static Assignment? parseText(String content) {
    if (content.isEmpty) {
      return null;
    }

    try {
      final orderIdMatch = RegExp(
        r'(?:Заказ|ID|Order|#)\s*:?\s*#?([A-Z0-9-]+)',
        caseSensitive: false,
      ).firstMatch(content);
      final orderId = orderIdMatch?.group(1) ?? 'Unknown';

      final clientMatch = RegExp(
        r'(?:Клиент|Получатель|Customer)\s*:\s*(.*)',
        caseSensitive: false,
      ).firstMatch(content);
      final clientName = clientMatch?.group(1)?.trim() ?? 'Розничный клиент';

      return Assignment(
        id: const Uuid().v4(),
        name: "Заказ $orderId - $clientName",
        type: "Warehouse Task",
        status: AssignmentStatus.inProgress,
        createdAt: DateTime.now(),
        items: [],
      );
    } catch (e) {
      return null;
    }
  }

  /// Helper to parse basic item quantities from text snippets
  static List<Map<String, dynamic>> parseItemList(String content) {
    final List<Map<String, dynamic>> items = [];
    final lines = content.split('\n');

    for (var line in lines) {
      if (line.contains('x')) {
        final parts = line.split('x');
        if (parts.length >= 2) {
          items.add({
            'name': parts[0].trim(),
            'quantity': int.tryParse(parts[1].trim()) ?? 1,
          });
        }
      }
    }
    return items;
  }
}

// Helper class to pass multiple arguments to compute()
class _ParseArgs {
  final Uint8List bytes;
  final String fileName;

  _ParseArgs(this.bytes, this.fileName);
}
