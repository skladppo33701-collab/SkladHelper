import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/models/product_model.dart';
// Note: We import storage_provider because that is where your Master Database lives now
import '../../catalog/providers/storage_provider.dart';

class PickupItem {
  final String code;
  final String name;
  final int requiredQty;
  int scannedQty;

  PickupItem({
    required this.code,
    required this.name,
    required this.requiredQty,
    this.scannedQty = 0,
  });

  bool get isCompleted => scannedQty >= requiredQty;
}

class PickupState {
  final String orderId;
  final List<PickupItem> items;

  PickupState({required this.orderId, required this.items});

  static PickupState fromJson(
    Map<String, dynamic> json,
    List<Product> catalog,
  ) {
    final items = (json['items'] as List).map((i) {
      final code = i['c'].toString();

      // Look up name in Master Catalog (storageProvider)
      final product = catalog.firstWhere(
        (p) => p.code == code,
        // FIX: Added 'storage' and 'quantity' to the fallback Product
        orElse: () => Product(
          code: code,
          name: "Неизвестный товар",
          category: "Unknown",
          storage: "Неизвестно",
          quantity: 0.0,
        ),
      );

      return PickupItem(
        code: code,
        name: product.name,
        requiredQty: (i['q'] as num).toInt(),
      );
    }).toList();

    return PickupState(
      orderId: json['id']?.toString() ?? 'Без номера',
      items: items,
    );
  }
}

// -----------------------------------------------------------------------------
// FIX: Migrated from StateNotifier to Notifier
// -----------------------------------------------------------------------------
class PickupNotifier extends Notifier<PickupState?> {
  @override
  PickupState? build() {
    return null; // Initial state is null (no order active)
  }

  void startSession(Map<String, dynamic> jsonData) {
    // We access the catalog via 'ref', which is built-in to Notifier
    final catalog = ref.read(storageProvider);
    state = PickupState.fromJson(jsonData, catalog);
  }

  void clearSession() {
    state = null;
  }

  bool scanItem(String code) {
    if (state == null) return false;

    // Find item index
    final index = state!.items.indexWhere((i) => i.code == code);
    if (index == -1) return false; // Item not in this order

    final item = state!.items[index];
    if (item.scannedQty >= item.requiredQty) {
      return false; // Already full
    }

    // Logic to update item inside the list immutably
    item.scannedQty++;

    // Force UI rebuild by creating new state object
    state = PickupState(
      orderId: state!.orderId,
      items: List.from(state!.items),
    );
    return true;
  }
}

// -----------------------------------------------------------------------------
// FIX: Switch to NotifierProvider
// -----------------------------------------------------------------------------
final pickupProvider = NotifierProvider<PickupNotifier, PickupState?>(() {
  return PickupNotifier();
});
