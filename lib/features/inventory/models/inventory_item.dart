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

  /// Calculates a relevance score for this item against a search query.
  /// Returns a double where higher is better.
  /// 0.0 means no relevant match found.
  double calculateRelevance(String query) {
    if (query.isEmpty) return 0.0;
    final lowerQuery = query.toLowerCase();

    // 1. Exact matches (Highest Priority)
    if (sku.toLowerCase() == lowerQuery) return 100.0;
    if (name.toLowerCase() == lowerQuery) return 90.0;
    if (brand.toLowerCase() == lowerQuery) return 85.0;

    // 2. Contains check (High Priority)
    // We award points based on how much of the string is consumed by the query
    if (sku.toLowerCase().contains(lowerQuery)) return 70.0;
    if (name.toLowerCase().contains(lowerQuery)) return 60.0;
    if (brand.toLowerCase().contains(lowerQuery)) return 55.0;

    // 3. Fuzzy Match (Levenshtein Distance)
    // Check against individual words in the name and brand
    double maxScore = 0.0;
    final List<String> tokens = [
      ...name.toLowerCase().split(' '),
      ...brand.toLowerCase().split(' '),
      sku.toLowerCase(),
    ];

    for (final token in tokens) {
      if (token.isEmpty) continue;

      final distance = _levenshtein(token, lowerQuery);
      final maxLength = token.length > lowerQuery.length
          ? token.length
          : lowerQuery.length;

      // Calculate similarity ratio (0.0 to 1.0)
      final double similarity = 1.0 - (distance / maxLength);

      // We only care about matches that are reasonably close (e.g., > 40% similar)
      if (similarity > 0.4) {
        // Scale score to be lower than 'contains' checks (e.g., max 50)
        final score = similarity * 50.0;
        if (score > maxScore) maxScore = score;
      }
    }

    return maxScore;
  }

  /// Helper method to maintain backward compatibility with code using .matches()
  /// Returns true if the fuzzy relevance score is greater than 0.
  bool matches(String query) {
    return calculateRelevance(query) > 0;
  }

  // Standard Levenshtein distance algorithm
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < t.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((min, val) => val < min ? val : min);
      }

      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
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
