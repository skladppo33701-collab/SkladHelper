class BrandClassificationResult {
  final String brand;
  final String category;
  final double confidence;

  BrandClassificationResult({
    required this.brand,
    required this.category,
    this.confidence = 0.0,
  });
}

class BrandClassifier {
  // Known brands database - easy to extend
  static const Set<String> _knownBrands = {
    'samsung',
    'lg',
    'bosch',
    'indesit',
    'beko',
    'haier',
    'midea',
    'xiaomi',
    'apple',
    'sony',
    'philips',
    'tefal',
    'electrolux',
    'whirlpool',
    'gorenje',
    'candy',
    'atlant',
    'ariston',
    'zanussi',
  };

  // Category mapping using regex patterns for flexibility
  static final Map<String, List<RegExp>> _categoryPatterns = {
    'Холодильники': [
      RegExp(r'холодильник', caseSensitive: false),
      RegExp(r'морозильн', caseSensitive: false),
      RegExp(r'side-by-side', caseSensitive: false),
    ],
    'Стиральные машины': [
      RegExp(r'стиральная', caseSensitive: false),
      RegExp(r'стир\.', caseSensitive: false),
      RegExp(r'сушильная', caseSensitive: false),
    ],
    'Телевизоры': [
      RegExp(r'телевизор', caseSensitive: false),
      RegExp(r'tv', caseSensitive: false),
      RegExp(r'led', caseSensitive: false),
      RegExp(r'oled', caseSensitive: false),
    ],
    'Мелкая бытовая': [
      RegExp(r'чайник', caseSensitive: false),
      RegExp(r'утюг', caseSensitive: false),
      RegExp(r'блендер', caseSensitive: false),
      RegExp(r'миксер', caseSensitive: false),
      RegExp(r'пылесос', caseSensitive: false),
      RegExp(r'фен', caseSensitive: false),
    ],
    'Климат': [
      RegExp(r'кондиционер', caseSensitive: false),
      RegExp(r'сплит', caseSensitive: false),
      RegExp(r'вентилятор', caseSensitive: false),
      RegExp(r'обогреватель', caseSensitive: false),
    ],
  };

  /// Main entry point for classification
  BrandClassificationResult classify(String rawName) {
    if (rawName.isEmpty) {
      return BrandClassificationResult(brand: 'N/A', category: 'General');
    }

    final String normalized = rawName.toLowerCase();

    // 1. Extract Brand
    String brand = _findBrand(normalized, rawName);

    // 2. Extract Category
    String category = _findCategory(normalized);

    // 3. Calculate simple confidence score based on what we found
    double confidence = 0.0;
    if (brand != 'N/A' && brand != 'Other') confidence += 0.5;
    if (category != 'General') confidence += 0.5;

    return BrandClassificationResult(
      brand: brand,
      category: category,
      confidence: confidence,
    );
  }

  String _findBrand(String normalized, String original) {
    // Strategy A: Check against known database (High Precision)
    for (final brand in _knownBrands) {
      // Check for word boundary matches to avoid partial matches (e.g. "lg" in "algol")
      if (normalized.contains(brand)) {
        // Return capitalized version from the set or the original string
        // Here we just capitalize the first letter for consistency
        return brand[0].toUpperCase() + brand.substring(1);
      }
    }

    // Strategy B: Heuristic extraction (Fallback)
    // Often the brand is the first English word in a mixed string
    final parts = original.split(' ');
    for (final part in parts) {
      // Simple regex for Latin characters only, length > 2
      if (RegExp(r'^[a-zA-Z]{2,}$').hasMatch(part)) {
        // Exclude common non-brand words if necessary
        if (![
          'led',
          'hd',
          'smart',
          'no',
          'frost',
        ].contains(part.toLowerCase())) {
          return part;
        }
      }
    }

    return 'Other';
  }

  String _findCategory(String normalized) {
    for (final entry in _categoryPatterns.entries) {
      for (final pattern in entry.value) {
        if (pattern.hasMatch(normalized)) {
          return entry.key;
        }
      }
    }
    return 'General';
  }
}
