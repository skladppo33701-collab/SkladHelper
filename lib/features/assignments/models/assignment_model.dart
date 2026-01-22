import 'package:uuid/uuid.dart';

enum AssignmentStatus { pending, inProgress, completed, archived }

class AssignmentItem {
  final String sku;
  final String name;
  final double quantity; // Total needed (e.g., 3)
  final double scannedAmount; // Scanned so far (e.g., 1)

  const AssignmentItem({
    required this.sku,
    required this.name,
    required this.quantity,
    this.scannedAmount = 0,
  });

  // Helper: Is this specific item fully done?
  bool get isFullyScanned => scannedAmount >= quantity;

  // Helper: "1/3" or just "1"
  String get progressText => "${scannedAmount.toInt()}/${quantity.toInt()}";

  AssignmentItem copyWith({double? scannedAmount}) {
    return AssignmentItem(
      sku: sku,
      name: name,
      quantity: quantity,
      scannedAmount: scannedAmount ?? this.scannedAmount,
    );
  }
}

class WarehouseAssignment {
  final String id;
  final String type; // "Накладная на перемещение"
  final String number; // "№ 52"
  final String date; // "22 января 2026 г."
  final List<AssignmentItem> items;
  final AssignmentStatus status;
  final DateTime createdAt;

  WarehouseAssignment({
    required this.id,
    required this.type,
    required this.number,
    required this.date,
    required this.items,
    this.status = AssignmentStatus.pending,
    required this.createdAt,
  });

  // Computed: 0.0 to 1.0
  double get progress {
    if (items.isEmpty) return 0;
    final total = items.fold(0.0, (sum, i) => sum + i.quantity);
    final scanned = items.fold(0.0, (sum, i) => sum + i.scannedAmount);
    return scanned / total;
  }
}
