enum AssignmentStatus { created, inProgress, completed }

class AssignmentItem {
  final String name;
  final String code; // or sku
  final double requiredQty;
  double scannedQty;

  AssignmentItem({
    required this.name,
    required this.code,
    required this.requiredQty,
    this.scannedQty = 0.0,
  });

  bool get isCompleted => scannedQty >= requiredQty;

  // FIX: Correct string interpolation
  String get progressText => '${scannedQty.toInt()}/${requiredQty.toInt()}';

  AssignmentItem copyWith({double? scannedQty}) {
    return AssignmentItem(
      name: name,
      code: code,
      requiredQty: requiredQty,
      scannedQty: scannedQty ?? this.scannedQty,
    );
  }
}

class Assignment {
  final String id;
  final String name;
  final String type;
  final DateTime createdAt;
  final List<AssignmentItem> items;
  AssignmentStatus status;

  Assignment({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.items,
    this.status = AssignmentStatus.created,
  });

  Assignment copyWith({
    String? id,
    String? name,
    String? type,
    DateTime? createdAt,
    List<AssignmentItem>? items,
    AssignmentStatus? status,
  }) {
    return Assignment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }

  bool get isReadyToComplete => items.every((i) => i.isCompleted);
}
