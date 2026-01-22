import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sklad_helper_33701/features/assignments/models/assignment_model.dart';
import 'package:sklad_helper_33701/features/assignments/providers/assignment_provider.dart';

class AssignmentDetailsPage extends ConsumerStatefulWidget {
  final String assignmentId;
  const AssignmentDetailsPage({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailsPage> createState() =>
      _AssignmentDetailsPageState();
}

class _AssignmentDetailsPageState extends ConsumerState<AssignmentDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(assignmentProvider);
    // Find current task
    final assignment = assignments.firstWhere(
      (a) => a.id == widget.assignmentId,
      orElse: () => throw Exception("Задание не найдено"),
    );

    // SPLIT LISTS logic
    final pending = assignment.items.where((i) => !i.isFullyScanned).toList();
    final done = assignment.items.where((i) => i.isFullyScanned).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.number,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              assignment.type,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMenu(context, assignment),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: "В работе (${pending.length})"),
            Tab(text: "Готово (${done.length})"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(pending, isDone: false),
          _buildList(done, isDone: true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _simulateScan(context), // Connect your real Scanner here
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text("СКАНИРОВАТЬ"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildList(List<AssignmentItem> items, {required bool isDone}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDone ? Icons.checklist_rtl : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isDone ? "Пока ничего не готово" : "Все товары собраны!",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 16, left: 16, right: 16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: isDone ? Colors.white.withValues(alpha: 0.6) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDone
                ? BorderSide.none
                : BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              item.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDone ? Colors.grey : Colors.black87,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "SKU: ${item.sku}",
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDone ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.progressText, // "1/3"
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDone ? Colors.green[700] : Colors.orange[800],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMenu(BuildContext context, WarehouseAssignment assignment) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Информация о задании'),
              onTap: () {}, // Show generic info dialog
            ),
            if (assignment.status == AssignmentStatus.completed)
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('В архив'),
                onTap: () {
                  ref
                      .read(assignmentProvider.notifier)
                      .archiveAssignment(assignment.id);
                  Navigator.pop(context); // Close menu
                  Navigator.pop(context); // Go back to dashboard
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.red),
              title: const Text(
                'Отменить задание',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _simulateScan(BuildContext context) {
    // Simulating scanning the FIRST pending item from the list
    // In real app: Open ScannerPage -> Get String -> Call scanItem(str)
    final assignments = ref.read(assignmentProvider);
    final assignment = assignments.firstWhere(
      (a) => a.id == widget.assignmentId,
    );
    final pending = assignment.items.where((i) => !i.isFullyScanned);

    if (pending.isNotEmpty) {
      final skuToScan = pending.first.sku;
      final success = ref
          .read(assignmentProvider.notifier)
          .scanItem(widget.assignmentId, skuToScan);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Успешно: ${pending.first.name}" : "Товар не найден",
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Задание уже выполнено!")));
    }
  }
}
