import 'package:flutter_riverpod/flutter_riverpod.dart';

// Make sure these imports point to your actual files
import '../models/assignment_model.dart'; // contains Assignment, AssignmentItem, AssignmentStatus
// import 'package:uuid/uuid.dart';               // if Uuid is used in model

final assignmentsProvider =
    NotifierProvider<AssignmentNotifier, List<Assignment>>(
      AssignmentNotifier.new,
    );

class AssignmentNotifier extends Notifier<List<Assignment>> {
  @override
  List<Assignment> build() {
    return []; // initial empty list
  }

  void addAssignment(Assignment assignment) {
    state = [...state, assignment];
  }

  /// Increment scanned quantity for a specific item in a specific assignment
  void updateItemScan(
    String assignmentId,
    String itemCode, {
    required double increment,
  }) {
    state = [
      for (final ass in state)
        if (ass.id == assignmentId)
          _updateScanned(ass, itemCode, increment)
        else
          ass,
    ];
  }

  Assignment _updateScanned(Assignment ass, String code, double inc) {
    final newItems = ass.items.map((item) {
      if (item.code == code) {
        return item.copyWith(scannedQty: item.scannedQty + inc);
      }
      return item;
    }).toList();

    final newStatus = newItems.every((i) => i.isCompleted)
        ? AssignmentStatus.completed
        : AssignmentStatus.inProgress;

    return ass.copyWith(items: newItems, status: newStatus);
  }

  void completeAssignment(String id) {
    state = [
      for (final ass in state)
        if (ass.id == id)
          ass.copyWith(status: AssignmentStatus.completed)
        else
          ass,
    ];
  }

  void deleteAssignment(String id) {
    state = state.where((a) => a.id != id).toList();
  }

  // Optional: archive method (if you want to move to archive instead of delete)
  void archiveAssignment(String id) {
    // You can either remove it or mark as archived
    // Example: just remove for now (same as delete)
    deleteAssignment(id);
    // Or: find and change status to archived if you add such enum value
  }
}
