// ──────────────────────────────────────────────────────────────
//  InventoryPage – Drag & Drop enriched version
// ──────────────────────────────────────────────────────────────

import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cross_file/cross_file.dart';
import 'package:intl/intl.dart';
import 'package:sklad_helper_33701/core/theme.dart';
import 'package:sklad_helper_33701/features/assignments/models/assignment_model.dart';
import 'package:sklad_helper_33701/features/assignments/providers/assignment_provider.dart';
import 'package:sklad_helper_33701/features/assignments/views/assignment_details_page.dart';
import 'package:uuid/uuid.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  bool _isDragging = false;
  bool _isProcessingDrop = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Stub parser – replace with your real SpreadsheetDecoder / PDF logic
  Future<Map<String, dynamic>> _parseDocument(
    Uint8List bytes,
    String fileName,
  ) async {
    // TODO: Implement real parsing here
    // For now return dummy data so the app runs
    return {
      'title': 'Накладная №${DateTime.now().millisecondsSinceEpoch % 10000}',
      'type': 'Накладная на перемещение',
      'items': [
        {'name': 'Холодильник Samsung RF-123', 'code': 'RF-123', 'qty': 2},
        {'name': 'Стиральная машина LG WM-456', 'code': 'WM-456', 'qty': 1},
        {'name': 'Микроволновка Bosch', 'code': 'MW-789', 'qty': 3},
      ],
    };
  }

  Future<void> _createAssignmentFromFile(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final parsed = await _parseDocument(bytes, fileName);

      final itemsList = parsed['items'] as List<dynamic>;
      final title =
          parsed['title'] as String? ??
          'Документ от ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}';
      final type = parsed['type'] as String? ?? 'Документ';

      final items = itemsList.map((m) {
        final map = m as Map<String, dynamic>;
        return AssignmentItem(
          name: map['name']?.toString() ?? '—',
          code: map['code']?.toString() ?? '',
          requiredQty: (map['qty'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      final assignment = Assignment(
        id: const Uuid().v4(),
        name: title,
        type: type,
        createdAt: DateTime.now(),
        items: items,
      );

      ref.read(assignmentsProvider.notifier).addAssignment(assignment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Задание создано: $title'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания задания: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    if (files.isEmpty) return;

    setState(() {
      _isProcessingDrop = true;
      _isDragging = false;
    });

    final allowedExt = {'csv', 'txt', 'xls', 'xlsx'};
    bool anySuccess = false;

    for (final file in files) {
      final ext = file.name.split('.').last.toLowerCase();
      if (!allowedExt.contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Пропущен неподдерживаемый файл: ${file.name}'),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
        continue;
      }

      try {
        final bytes = await file.readAsBytes();
        await _createAssignmentFromFile(bytes, file.name);
        anySuccess = true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка обработки ${file.name}: $e'),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isProcessingDrop = false);

      if (anySuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Файл(ы) успешно обработаны'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          Text(
            'Нет активных заданий',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            'Загрузите файл или перетащите накладную',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SkladColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignments = ref.watch(assignmentsProvider);

    return Scaffold(
      backgroundColor: colors.surfaceLow,
      appBar: AppBar(title: const Text('Задания / Накладные')),
      body: DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: (detail) => _handleDroppedFiles(detail.files),
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Optional search bar
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск задания...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: assignments.isEmpty
                        ? _buildEmptyPlaceholder()
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: assignments.length,
                            itemBuilder: (context, i) {
                              final ass = assignments[i];
                              final isCompleted =
                                  ass.status == AssignmentStatus.completed;

                              return Dismissible(
                                key: ValueKey(ass.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 32),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                onDismissed: (_) {
                                  ref
                                      .read(assignmentsProvider.notifier)
                                      .deleteAssignment(ass.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Задание удалено'),
                                    ),
                                  );
                                },
                                child: Card(
                                  color: isCompleted
                                      ? colors.neutralGray.withValues(
                                          alpha: 0.35,
                                        )
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    title: Text(
                                      ass.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isCompleted
                                            ? colors.neutralGray
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      DateFormat(
                                        'dd MMM yyyy • HH:mm',
                                      ).format(ass.createdAt),
                                      style: TextStyle(
                                        color: colors.neutralGray,
                                      ),
                                    ),
                                    trailing: isCompleted
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onTap: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Открыть задание?'),
                                          content: Text(ass.name),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Отмена'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Открыть'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true &&
                                          context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AssignmentDetailsPage(
                                                  assignmentId: ass.id,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // Drag overlay
            if (_isDragging || _isProcessingDrop)
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 280),
                  child: Container(
                    color: isDark
                        ? Colors.grey.shade900.withValues(alpha: 0.62)
                        : Colors.grey.shade800.withValues(alpha: 0.55),
                    child: Center(
                      child: ScaleTransition(
                        scale: _isProcessingDrop
                            ? Tween<double>(begin: 0.88, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: AnimationController(
                                    vsync: this,
                                    duration: const Duration(milliseconds: 650),
                                  )..forward(),
                                  curve: Curves.elasticOut,
                                ),
                              )
                            : _pulseAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                    opacity: anim,
                                    child: ScaleTransition(
                                      scale: anim,
                                      child: child,
                                    ),
                                  ),
                              child: Icon(
                                _isProcessingDrop
                                    ? Icons.cloud_done_rounded
                                    : Icons.cloud_upload_outlined,
                                key: ValueKey<bool>(_isProcessingDrop),
                                size: 100,
                                color: _isProcessingDrop
                                    ? colors.accentAction
                                    : Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              _isProcessingDrop
                                  ? 'Обработка...'
                                  : 'Отпустите файлы',
                              style: GoogleFonts.inter(
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                color: _isProcessingDrop
                                    ? colors.accentAction
                                    : Colors.white.withValues(alpha: 0.96),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Поддерживаются: .csv .txt .xls .xlsx',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
