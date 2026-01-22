import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment_model.dart';
import '../services/assignment_parser.dart';

class AssignmentNotifier extends Notifier<List<WarehouseAssignment>> {
  @override
  List<WarehouseAssignment> build() => [];

  void importFromCsv(String csvContent) {
    final assignment = AssignmentParser().parseCsv(csvContent);
    state = [...state, assignment];
  }

  /// The Core Scanning Logic
  /// Returns [true] if scan was valid (item found and incremented)
  bool scanItem(String assignmentId, String scannedBarcode) {
    bool found = false;

    state = [
      for (final assignment in state)
        if (assignment.id == assignmentId)
          _processScan(assignment, scannedBarcode, (isValid) => found = isValid)
        else
          assignment,
    ];

    return found;
  }

  WarehouseAssignment _processScan(
    WarehouseAssignment task,
    String barcode,
    Function(bool) onResult,
  ) {
    // 1. Find the item that needs this SKU
    final index = task.items.indexWhere(
      (item) => item.sku == barcode && !item.isFullyScanned,
    );

    if (index == -1) {
      onResult(false); // Not found or already done
      return task;
    }

    // 2. Increment count (1/3 -> 2/3)
    final newItems = [...task.items];
    final current = newItems[index];

    newItems[index] = current.copyWith(
      scannedAmount: current.scannedAmount + 1,
    );

    onResult(true);

    // 3. Auto-update status if ALL items are done
    final isComplete = newItems.every((i) => i.isFullyScanned);
    return WarehouseAssignment(
      id: task.id,
      type: task.type,
      number: task.number,
      date: task.date,
      createdAt: task.createdAt,
      items: newItems,
      status: isComplete
          ? AssignmentStatus.completed
          : AssignmentStatus.inProgress,
    );
  }

  void archiveAssignment(String id) {
    state = state.where((a) => a.id != id).toList();
    // In a real app, save to Firestore 'archive' collection here
  }
}

final assignmentProvider =
    NotifierProvider<AssignmentNotifier, List<WarehouseAssignment>>(
      AssignmentNotifier.new,
    );
