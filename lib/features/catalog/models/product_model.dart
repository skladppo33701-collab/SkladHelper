class Product {
  final String code;
  final String name;
  final String category;
  final String storage;
  final double quantity;

  Product({
    required this.code,
    required this.name,
    required this.category,
    required this.storage,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'c': code,
    'n': name,
    'cat': category,
    'loc': storage,
    'q': quantity,
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      code: json['c']?.toString() ?? '',
      name: json['n']?.toString() ?? '',
      category: json['cat']?.toString() ?? '',
      storage: json['loc']?.toString() ?? '',
      quantity: (json['q'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
