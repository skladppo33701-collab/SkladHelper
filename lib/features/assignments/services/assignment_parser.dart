import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../models/assignment_model.dart';

class AssignmentParser {
  WarehouseAssignment parseCsv(String csvContent) {
    // 1. Convert CSV to List of Lists
    List<List<dynamic>> rows = const CsvToListConverter().convert(
      csvContent,
      eol: '\n',
    );

    String type = "Документ";
    String number = "";
    String date = "";
    List<AssignmentItem> items = [];

    bool headerFound = false;
    int colSku = -1;
    int colName = -1;
    int colQty = -1;

    for (var row in rows) {
      if (row.isEmpty) continue;

      final rowStrings = row.map((e) => e.toString().trim()).toList();
      final fullLine = rowStrings.join(' ');

      // 2. Smart Header Extraction
      // Target: "Накладная на перемещение № 52 от 22 января 2026 г."
      if (fullLine.contains('№') && fullLine.contains('от')) {
        try {
          // Split by "№" -> ["Накладная на перемещение", "52 от 22..."]
          final parts = fullLine.split('№');
          type = parts[0].trim();
          if (type.endsWith(',')) type = type.substring(0, type.length - 1);

          // Split remaining by "от" -> ["52", "22 января..."]
          final subParts = parts[1].split('от');
          number = "№ ${subParts[0].trim()}";
          date = "от ${subParts[1].trim()}";

          // Clean up trailing CSV commas in date
          if (date.contains(',')) date = date.split(',')[0];
        } catch (_) {
          // Fallback if format varies slightly
          type = fullLine;
        }
      }

      // 3. Find Table Headers
      if (!headerFound) {
        // Look for keywords "Артикул" (SKU) and "Товар" (Product)
        if (rowStrings.contains('Артикул') && rowStrings.contains('Товар')) {
          headerFound = true;
          for (int i = 0; i < row.length; i++) {
            final val = row[i].toString().trim();
            if (val == 'Артикул') colSku = i;
            if (val == 'Товар') colName = i;
            if (val == 'Количество') colQty = i;
          }
          continue;
        }
      }

      // 4. Parse Rows
      if (headerFound && colSku != -1 && colQty != -1 && row.length > colQty) {
        String sku = row[colSku].toString().trim();
        String name = row[colName].toString().trim();
        String qtyStr = row[colQty].toString().trim();

        // Skip categories or empty lines
        if (sku.isEmpty || name.isEmpty || qtyStr.isEmpty) continue;

        double? qty = double.tryParse(qtyStr);
        if (qty != null && qty > 0) {
          items.add(AssignmentItem(sku: sku, name: name, quantity: qty));
        }
      }
    }

    return WarehouseAssignment(
      id: const Uuid().v4(),
      type: type,
      number: number,
      date: date,
      items: items,
      createdAt: DateTime.now(),
    );
  }
}
