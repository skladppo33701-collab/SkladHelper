import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/assignment_model.dart';
import '../../providers/assignment_provider.dart';

class AssignmentCard extends ConsumerWidget {
  final WarehouseAssignment assignment;
  final VoidCallback onTap;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = assignment.progress;
    final isDone = progress >= 1.0;

    // Swipe-to-Action logic
    return Dismissible(
      key: ValueKey(assignment.id),
      direction: DismissDirection.startToEnd, // Left to right
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.green,
        child: const Row(
          children: [
            Icon(Icons.archive_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "В архив",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Confirmation dialog
        if (!isDone) return false; // Only allow archiving if done? (Optional)
        return true;
      },
      onDismissed: (_) {
        ref.read(assignmentProvider.notifier).archiveAssignment(assignment.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Задание перемещено в архив")),
        );
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            assignment.number,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDone)
                      const Icon(Icons.check_circle, color: Colors.green)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${(progress * 100).toInt()}%",
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Footer
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      assignment.date,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
