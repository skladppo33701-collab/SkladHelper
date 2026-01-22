class InventoryItem {
  final String id;
  final String sku;
  final String name;
  final double quantity;
  final String warehouse;
  final String brand;
  final String category;

  const InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.warehouse,
    this.brand = '',
    this.category = 'General',
  });

  // FIX: Added this method for search functionality
  bool matches(String query) {
    final lower = query.toLowerCase();
    return name.toLowerCase().contains(lower) ||
        sku.toLowerCase().contains(lower) ||
        brand.toLowerCase().contains(lower);
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map, String docId) {
    return InventoryItem(
      id: docId,
      sku: map['sku'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      warehouse: map['warehouse'] ?? '',
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
    );
  }
}
