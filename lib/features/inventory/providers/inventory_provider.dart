import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';

class InventoryState {
  final bool isLoading;
  final List<InventoryItem> allItems;
  final List<InventoryItem> filteredItems;

  InventoryState({
    this.isLoading = false,
    this.allItems = const [],
    this.filteredItems = const [],
  });

  InventoryState copyWith({
    bool? isLoading,
    List<InventoryItem>? allItems,
    List<InventoryItem>? filteredItems,
  }) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
    );
  }
}

class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() => InventoryState();

  void search(String query) {
    if (query.isEmpty) {
      state = state.copyWith(filteredItems: state.allItems);
      return;
    }
    final filtered = state.allItems
        .where((item) => item.matches(query))
        .toList();
    state = state.copyWith(filteredItems: filtered);
  }

  Future<void> parseCsvData(String csvContent) async {
    state = state.copyWith(isLoading: true);

    try {
      final List<InventoryItem> newItems = [];
      final List<String> lines = const LineSplitter().convert(csvContent);

      String delimiter = ',';
      if (lines.any((l) => l.contains(';'))) {
        delimiter = ';';
      }

      int colSku = -1;
      int colName = -1;
      int colQty = -1;
      bool headerFound = false;

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        final List<String> cells = line
            .split(delimiter)
            .map((e) => e.trim())
            .toList();

        if (!headerFound) {
          final lowerCells = cells.map((e) => e.toLowerCase()).toList();
          if (lowerCells.contains('артикул') && lowerCells.contains('товар')) {
            headerFound = true;
            for (int i = 0; i < cells.length; i++) {
              final val = cells[i].toLowerCase();
              if (val.contains('артикул')) {
                colSku = i;
              } else if (val.contains('товар')) {
                colName = i;
              } else if (val.contains('количество')) {
                colQty = i;
              }
            }
          }
          continue;
        }

        if (headerFound && colSku != -1 && colName != -1 && colQty != -1) {
          if (cells.length <= colQty) continue;

          String sku = cells[colSku];
          String name = cells[colName];
          String qtyStr = cells[colQty];

          if (sku.isEmpty || name.isEmpty) continue;

          qtyStr = qtyStr.replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
          double qty = double.tryParse(qtyStr) ?? 0;

          if (qty > 0) {
            newItems.add(
              InventoryItem(
                id: sku, // FIX: Added required id
                sku: sku,
                name: name,
                quantity: qty,
                brand: _extractBrand(name),
                warehouse: "Основной склад",
                category: "Общее",
              ),
            );
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        allItems: newItems,
        filteredItems: newItems,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  String _extractBrand(String name) {
    final parts = name.split(' ');
    if (parts.length > 2 && parts[0].toLowerCase() == 'холодильник') {
      return parts[1];
    }
    if (parts.length > 2 && parts[0].toLowerCase() == 'стиральная') {
      return parts[2];
    }
    if (parts.length > 1) return parts[0];
    return "N/A";
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(
  () => InventoryNotifier(),
);
