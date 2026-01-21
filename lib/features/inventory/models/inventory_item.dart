class InventoryItem {
  final String name;
  final String sku;
  final double quantity;
  final String brand;
  final String warehouse;

  InventoryItem({
    required this.name,
    required this.sku,
    required this.quantity,
    required this.brand,
    required this.warehouse,
  });

  // Basic search logic
  bool matches(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) || sku.contains(q);
  }
}
