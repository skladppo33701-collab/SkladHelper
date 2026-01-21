import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import '../models/inventory_item.dart';

class InventoryState {
  final bool isLoading;
  final List<InventoryItem> allItems;
  final List<InventoryItem> filteredItems;
  final String selectedWarehouse;
  final String searchQuery;

  InventoryState({
    this.isLoading = false,
    this.allItems = const [],
    this.filteredItems = const [],
    this.selectedWarehouse = 'All',
    this.searchQuery = '',
  });

  InventoryState copyWith({
    bool? isLoading,
    List<InventoryItem>? allItems,
    List<InventoryItem>? filteredItems,
    String? selectedWarehouse,
    String? searchQuery,
  }) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      selectedWarehouse: selectedWarehouse ?? this.selectedWarehouse,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// FIX: Changed from StateNotifier to Notifier
class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() {
    return InventoryState(); // Initial state
  }

  Future<void> parseCsvData(String csvString) async {
    state = state.copyWith(isLoading: true);

    try {
      // Parse CSV
      List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
      );

      List<InventoryItem> parsedItems = [];
      String currentWarehouse = 'Main';
      String currentBrand = 'Other';
      bool dataStarted = false;

      for (var row in rows) {
        if (row.length < 3) continue;

        String colA = row[0].toString().trim();
        String colB = row[1].toString().trim(); // SKU
        String colC = row[2].toString().trim(); // Qty

        // Detect Warehouse (specific to your 1C format)
        if (colA.startsWith('33701_')) {
          currentWarehouse = colA.split(' ').sublist(0, 2).join(' ');
          dataStarted = true;
          continue;
        }

        if (!dataStarted) continue;

        // Detect Brand (Text in A, Empty B, Number in C)
        if (colB.isEmpty && colA.isNotEmpty && double.tryParse(colC) != null) {
          currentBrand = colA;
          continue;
        }

        // Detect Item (Has SKU)
        if (colB.isNotEmpty) {
          parsedItems.add(
            InventoryItem(
              name: colA,
              sku: colB,
              quantity: double.tryParse(colC) ?? 0.0,
              brand: currentBrand,
              warehouse: currentWarehouse,
            ),
          );
        }
      }

      state = state.copyWith(
        isLoading: false,
        allItems: parsedItems,
        filteredItems: parsedItems,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Use standard logging in production apps, avoided print for linter compliance
      // log("Error parsing CSV: $e");
    }
  }

  void search(String query) {
    final filtered = state.allItems.where((item) {
      final matchesSearch = item.matches(query);
      final matchesWarehouse =
          state.selectedWarehouse == 'All' ||
          item.warehouse == state.selectedWarehouse;
      return matchesSearch && matchesWarehouse;
    }).toList();

    state = state.copyWith(searchQuery: query, filteredItems: filtered);
  }
}

// FIX: Use NotifierProvider instead of StateNotifierProvider
final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(
  InventoryNotifier.new,
);
