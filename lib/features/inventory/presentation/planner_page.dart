import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:sklad_helper_33701/core/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum Importance { low, medium, high, critical }

class Task {
  final String id;
  final String title;
  final DateTime date;
  final List<TimeOfDay> reminders;
  final int recurrenceMode;
  final bool isShared;
  final Importance importance;
  final String creatorName;
  final String? creatorPfpUrl;
  final Set<int> selectedWeekdays;
  final Set<int> selectedMonthDays;
  final int? xDays;
  final int? yDays;
  final DateTime? cycleStartDate;

  Task({
    required this.id,
    required this.title,
    required this.date,
    required this.reminders,
    required this.recurrenceMode,
    required this.isShared,
    required this.importance,
    required this.creatorName,
    this.creatorPfpUrl,
    this.selectedWeekdays = const {},
    this.selectedMonthDays = const {},
    this.xDays,
    this.yDays,
    this.cycleStartDate,
  });

  factory Task.fromMap(Map<String, dynamic> map, String documentId) {
    return Task(
      id: documentId,
      title: map['title'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      reminders: (map['reminders'] as List? ?? []).map((r) {
        return TimeOfDay(hour: r['h'] ?? 0, minute: r['m'] ?? 0);
      }).toList(),
      recurrenceMode: map['recurrenceMode'] ?? 0,
      isShared: map['isShared'] ?? false,
      importance: Importance.values[map['importance'] ?? 0],
      creatorName: map['creatorName'] ?? 'Manager',
      creatorPfpUrl: map['creatorPfpUrl'],
      selectedWeekdays: Set<int>.from(map['selectedWeekdays'] ?? {}),
      selectedMonthDays: Set<int>.from(map['selectedMonthDays'] ?? {}),
      xDays: map['xDays'],
      yDays: map['yDays'],
      cycleStartDate: map['cycleStartDate'] != null
          ? DateTime.parse(map['cycleStartDate'])
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLANNER PAGE
// ─────────────────────────────────────────────────────────────────────────────

class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  int _selectedView = 0; // 0: Personal, 1: Shared
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _taskController = TextEditingController();
  final ScrollController _dateScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearchMode = false;
  bool _titleTouched = false;
  bool _isSaving = false;

  // Temporary sheet state variables
  int _tempRecurrenceMode = 0;
  final List<TimeOfDay> _tempReminders = [];
  final Set<int> _tempWeekdays = {};
  final Set<int> _tempMonthDays = {};
  int _tempX = 1;
  int _tempY = 1;
  DateTime _tempCycleStart = DateTime.now();

  @override
  void dispose() {
    _taskController.dispose();
    _dateScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _jumpToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      if (_isSearchMode) {
        _isSearchMode = false;
        _searchController.clear();
      }
    });

    if (_dateScrollController.hasClients) {
      _dateScrollController.animateTo(
        64, // Offset to show yesterday partially
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showNotification(String message, IconData icon, Color color) {
    if (!mounted) return;
    final colors = Theme.of(context).extension<SkladColors>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: colors.contentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fixed: Expanded dates to 3 months (92 days) starting from yesterday
  List<DateTime> _generateDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(
      92,
      (i) => today.subtract(const Duration(days: 1)).add(Duration(days: i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SkladColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTodaySelected = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: colors.surfaceLow,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 44, 24, 12),
              color: colors.surfaceContainer,
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                      child: _isSearchMode
                          ? TextField(
                              key: const ValueKey("SearchField"),
                              controller: _searchController,
                              autofocus: true,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: colors.contentPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Поиск задач...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: colors.contentTertiary,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            )
                          : Align(
                              key: const ValueKey("TitleHeader"),
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Планировщик",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 26,
                                      color: colors.contentPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    "${DateFormat('LLLL yyyy', 'ru').format(DateTime.now())}г.",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: colors.contentSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  Row(
                    children: [
                      if (!_isSearchMode && !isTodaySelected)
                        IconButton(
                          onPressed: _jumpToToday,
                          icon: Icon(
                            Icons.history_rounded,
                            color: colors.accentAction,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.accentAction.withValues(
                              alpha: 0.1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isSearchMode = !_isSearchMode;
                            if (!_isSearchMode) _searchController.clear();
                          });
                        },
                        icon: Icon(
                          _isSearchMode
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.surfaceHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (!_isSearchMode)
            SliverToBoxAdapter(
              child: Container(
                height: 115,
                color: colors.surfaceContainer,
                child: ListView.builder(
                  controller: _dateScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: _generateDates().length,
                  itemBuilder: (context, index) {
                    final date = _generateDates()[index];
                    final isSelected = DateUtils.isSameDay(date, _selectedDate);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 58,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.accentAction
                              : colors.surfaceHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? colors.accentAction
                                : colors.divider,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E', 'ru').format(date).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : colors.contentTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              date.day.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isSelected
                                    ? Colors.white
                                    : colors.contentPrimary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              DateFormat(
                                'MMM',
                                'ru',
                              ).format(date).replaceAll('.', ''),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : colors.contentTertiary.withValues(
                                        alpha: 0.6,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            sliver: SliverToBoxAdapter(
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.divider),
                ),
                child: Row(
                  children: [
                    _buildSwitchTab(0, "Личные", colors),
                    _buildSwitchTab(1, "Общие", colors),
                  ],
                ),
              ),
            ),
          ),

          SliverFillRemaining(
            hasScrollBody: true,
            child: _buildTaskList(colors, isDark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _titleTouched = false;
          _showTaskSheet(context);
        },
        backgroundColor: colors.accentAction,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(
          Icons.add_task_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildSwitchTab(int mode, String label, SkladColors colors) {
    final isSelected = _selectedView == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentAction : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : colors.contentSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(SkladColors proColors, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final allTasks = snapshot.data!.docs
            .map(
              (doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .toList();

        final filteredTasks = allTasks.where((t) {
          if (t.isShared != (_selectedView == 1)) return false;
          if (_isSearchMode) {
            if (_searchController.text.isEmpty) return true;
            return t.title.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
          }
          switch (t.recurrenceMode) {
            case 0:
              return DateUtils.isSameDay(t.date, _selectedDate);
            case 1:
              return t.selectedWeekdays.contains(_selectedDate.weekday - 1);
            case 2:
              return t.selectedMonthDays.contains(_selectedDate.day);
            case 3:
              return _isDateInXYCycle(
                _selectedDate,
                t.cycleStartDate ?? t.date,
                t.xDays ?? 1,
                t.yDays ?? 1,
              );
            default:
              return false;
          }
        }).toList();

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: filteredTasks.isEmpty
              ? _buildEmptyState(proColors, isSearch: _isSearchMode)
              : ListView.builder(
                  key: ValueKey(
                    "TaskList_${_selectedDate.toIso8601String()}_$_isSearchMode",
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildCompactTaskCard(
                      filteredTasks[index],
                      proColors,
                      isDark,
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCompactTaskCard(Task task, SkladColors colors, bool isDark) {
    final statusColor = _getImportanceColor(task.importance, colors);
    final userAsync = ref.watch(userRoleProvider);
    final currentUserName = userAsync.asData?.value?.name ?? 'Вы';

    return Slidable(
      key: Key(task.id),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (context) => _showTaskSheet(context, existingTask: task),
            backgroundColor: colors.accentAction,
            foregroundColor: Colors.white,
            icon: Icons.edit_note_rounded,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (context) => _deleteTaskFromFirebase(task.id),
            backgroundColor: colors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(16),
            ),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colors.contentPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      task.reminders.isNotEmpty
                                          ? task.reminders.first.format(context)
                                          : "Без врем.",
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: colors.contentSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildImportanceBadge(
                                    task.importance,
                                    colors,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (task.isShared)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colors.divider),
                                ),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: colors.surfaceContainer,
                                  backgroundImage:
                                      (task.creatorPfpUrl != null &&
                                          task.creatorPfpUrl!.isNotEmpty)
                                      ? NetworkImage(task.creatorPfpUrl!)
                                      : null,
                                  child:
                                      (task.creatorPfpUrl == null ||
                                          task.creatorPfpUrl!.isEmpty)
                                      ? Text(
                                          task.creatorName[0].toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: colors.accentAction,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                task.creatorName == currentUserName
                                    ? "Вы"
                                    : task.creatorName.split(' ').first,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: colors.contentTertiary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImportanceBadge(Importance imp, SkladColors colors) {
    String label;
    Color color = _getImportanceColor(imp, colors);
    switch (imp) {
      case Importance.low:
        label = "НИЗ";
        break;
      case Importance.medium:
        label = "СРД";
        break;
      case Importance.high:
        label = "ВЫС";
        break;
      case Importance.critical:
        label = "КРИТ";
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  // --- FULL TASK SHEET LOGIC ---

  void _showTaskSheet(BuildContext context, {Task? existingTask}) {
    final userAsync = ref.watch(userRoleProvider);
    if (userAsync.value == null) return;
    final currentUser = userAsync.value!;

    Importance localImportance = existingTask?.importance ?? Importance.low;
    bool localIsShared = existingTask?.isShared ?? (_selectedView == 1);

    if (existingTask != null) {
      _taskController.text = existingTask.title;
      _tempRecurrenceMode = existingTask.recurrenceMode;
      _tempReminders
        ..clear()
        ..addAll(existingTask.reminders);
      _selectedDate = existingTask.date;
      _tempWeekdays
        ..clear()
        ..addAll(existingTask.selectedWeekdays);
      _tempMonthDays
        ..clear()
        ..addAll(existingTask.selectedMonthDays);
      _tempX = existingTask.xDays ?? 1;
      _tempY = existingTask.yDays ?? 1;
      _tempCycleStart = existingTask.cycleStartDate ?? existingTask.date;
    } else {
      _taskController.clear();
      _tempRecurrenceMode = 0;
      _tempReminders.clear();
      _tempWeekdays.clear();
      _tempMonthDays.clear();
      _tempX = 1;
      _tempY = 1;
      _tempCycleStart = DateTime.now();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final colors = Theme.of(context).extension<SkladColors>()!;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          // Logic for Points 2 & 3: Yesterday is allowed, but we show a small warning
          final today = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          );
          final yesterday = today.subtract(const Duration(days: 1));
          final isPast = _selectedDate.isBefore(today);

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fixed Point 3: Small, compatible "Passed Date" Notification inside sheet
                  if (isPast)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.warning.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 14,
                            color: colors.warning,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Задача в прошлом",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Text(
                    existingTask == null ? "Новая задача" : "Редактировать",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _taskController,
                    autofocus: true,
                    onChanged: (_) => setSheetState(() {}),
                    onTap: () => setSheetState(() => _titleTouched = true),
                    style: TextStyle(color: colors.contentPrimary),
                    decoration: _inputDecoration(
                      hint: "Назовите задачу...",
                      isDark: isDark,
                      colors: colors,
                      errorText:
                          (_titleTouched && _taskController.text.trim().isEmpty)
                          ? "Обязательное имя"
                          : null,
                    ),
                  ),

                  _buildLabel("ТИП ЗАДАЧИ"),
                  Row(
                    children: [
                      _typeChip(
                        "Личная",
                        !localIsShared,
                        colors,
                        () => setSheetState(() => localIsShared = false),
                      ),
                      const SizedBox(width: 12),
                      _typeChip(
                        "Общая",
                        localIsShared,
                        colors,
                        () => setSheetState(() => localIsShared = true),
                      ),
                    ],
                  ),

                  _buildLabel("ВАЖНОСТЬ"),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: Importance.values
                          .map(
                            (i) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _importanceOption(
                                i,
                                localImportance == i,
                                colors,
                                () => setSheetState(() => localImportance = i),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  _buildLabel("ПОВТОРЕНИЕ"),
                  _recurrenceToggle(
                    colors,
                    (m) => setSheetState(() => _tempRecurrenceMode = m),
                  ),

                  const SizedBox(height: 16),
                  _buildDetailedRecurrenceContent(
                    colors,
                    isDark,
                    setSheetState,
                  ),

                  _buildLabel("УВЕДОМЛЕНИЯ"),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._tempReminders.map(
                        (t) => GestureDetector(
                          onTap: () => _showCupertinoTimePicker(
                            context,
                            isDark,
                            colors,
                            t,
                            (newTime) {
                              if (!ctx.mounted) return;
                              setSheetState(() {
                                int idx = _tempReminders.indexOf(t);
                                if (idx != -1) _tempReminders[idx] = newTime;
                              });
                            },
                          ),
                          child: _reminderChip(
                            t.format(context),
                            colors,
                            () => setSheetState(() => _tempReminders.remove(t)),
                          ),
                        ),
                      ),
                      _addTimeButton(context, colors, isDark, (t) {
                        setSheetState(() {
                          if (!_tempReminders.contains(t)) {
                            _tempReminders.add(t);
                          }
                        });
                      }),
                    ],
                  ),

                  // Fixed Point 7: Less space after reminder section and before buttons
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.divider),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("Отмена"),
                        ),
                      ),
                      const SizedBox(width: 8), // Fixed Point 7: Tightened gap
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  if (_taskController.text.trim().isEmpty) {
                                    setSheetState(() => _titleTouched = true);
                                    return;
                                  }
                                  // Fixed Point 2: Allow yesterday but block further past
                                  if (_selectedDate.isBefore(yesterday)) {
                                    _showNotification(
                                      "Слишком старая дата",
                                      Icons.warning_rounded,
                                      colors.error,
                                    );
                                    return;
                                  }

                                  setSheetState(() => _isSaving = true);
                                  try {
                                    final task = Task(
                                      id: existingTask?.id ?? "",
                                      title: _taskController.text.trim(),
                                      date: _selectedDate,
                                      reminders: _tempReminders,
                                      recurrenceMode: _tempRecurrenceMode,
                                      isShared: localIsShared,
                                      importance: localImportance,
                                      creatorName: currentUser.name,
                                      creatorPfpUrl: currentUser.photoUrl,
                                      selectedWeekdays: _tempWeekdays,
                                      selectedMonthDays: _tempMonthDays,
                                      xDays: _tempX,
                                      yDays: _tempY,
                                      cycleStartDate: _tempCycleStart,
                                    );
                                    await _saveTaskToDatabase(task);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (e) {
                                    _showNotification(
                                      "Ошибка сохранения",
                                      Icons.error,
                                      colors.error,
                                    );
                                  } finally {
                                    // Fixed Point 5: Always reset loading state
                                    if (ctx.mounted) {
                                      setSheetState(() => _isSaving = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accentAction,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const CupertinoActivityIndicator(
                                  color: Colors.white,
                                )
                              : const Text("Сохранить"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- RECURRENCE MODE SPECIFIC BUILDERS ---

  Widget _buildDetailedRecurrenceContent(
    SkladColors colors,
    bool isDark,
    StateSetter setSheetState,
  ) {
    if (_tempRecurrenceMode == 0) {
      return GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime.now().subtract(
              const Duration(days: 1),
            ), // Fixed: yesterday
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (mounted && picked != null) {
            setSheetState(() => _selectedDate = picked);
          }
        },
        child: _buildRecurrenceBox(
          DateFormat('d MMMM, yyyy', 'ru').format(_selectedDate),
          Icons.calendar_today_rounded,
          colors,
        ),
      );
    }

    if (_tempRecurrenceMode == 1) {
      final days = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"];
      // Fixed Point 6: Week days closer and tight
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(
          7,
          (i) => GestureDetector(
            onTap: () => setSheetState(
              () => _tempWeekdays.contains(i)
                  ? _tempWeekdays.remove(i)
                  : _tempWeekdays.add(i),
            ),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _tempWeekdays.contains(i)
                    ? colors.accentAction
                    : colors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                days[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _tempWeekdays.contains(i)
                      ? Colors.white
                      : colors.contentSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_tempRecurrenceMode == 2) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: 31,
        itemBuilder: (context, i) {
          final d = i + 1;
          final active = _tempMonthDays.contains(d);
          return GestureDetector(
            onTap: () => setSheetState(
              () => active ? _tempMonthDays.remove(d) : _tempMonthDays.add(d),
            ),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? colors.accentAction : colors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                "$d",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? Colors.white : colors.contentPrimary,
                ),
              ),
            ),
          );
        },
      );
    }

    if (_tempRecurrenceMode == 3) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSmallNumInput(
                  "РАБОТА (X)",
                  _tempX,
                  (v) => setSheetState(() => _tempX = v),
                  colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallNumInput(
                  "ОТДЫХ (Y)",
                  _tempY,
                  (v) => setSheetState(() => _tempY = v),
                  colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tempCycleStart,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (mounted && picked != null) {
                setSheetState(() => _tempCycleStart = picked);
              }
            },
            child: _buildRecurrenceBox(
              "Начало: ${DateFormat('d MMM').format(_tempCycleStart)}",
              Icons.play_arrow_rounded,
              colors,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  void _showCupertinoTimePicker(
    BuildContext context,
    bool isDark,
    SkladColors colors,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onSelected,
  ) {
    TimeOfDay temp = initial;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: colors.surfaceHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      "Отмена",
                      style: TextStyle(color: colors.contentSecondary),
                    ),
                  ),
                  Text(
                    "Время",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: colors.contentPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onSelected(temp);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(
                      "Готово",
                      style: TextStyle(
                        color: colors.accentAction,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: isDark ? Brightness.dark : Brightness.light,
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(
                    2024,
                    1,
                    1,
                    initial.hour,
                    initial.minute,
                  ),
                  onDateTimeChanged: (dt) =>
                      temp = TimeOfDay(hour: dt.hour, minute: dt.minute),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UTILS ---

  Widget _buildRecurrenceBox(String text, IconData icon, SkladColors colors) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.accentAction),
            const SizedBox(width: 12),
            Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _buildSmallNumInput(
    String label,
    int val,
    Function(int) onCh,
    SkladColors colors,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
      const SizedBox(height: 4),
      TextField(
        keyboardType: TextInputType.number,
        onChanged: (s) => onCh(int.tryParse(s) ?? 1),
        decoration: InputDecoration(
          hintText: "$val",
          filled: true,
          fillColor: colors.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _typeChip(
    String label,
    bool active,
    SkladColors colors,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: active ? colors.accentAction : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : colors.contentSecondary,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );

  Widget _importanceOption(
    Importance i,
    bool active,
    SkladColors colors,
    VoidCallback onTap,
  ) {
    String label;
    switch (i) {
      case Importance.low:
        label = "Низкая";
        break;
      case Importance.medium:
        label = "Средняя";
        break;
      case Importance.high:
        label = "Высокая";
        break;
      case Importance.critical:
        label = "Критич.";
        break;
    }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? _getImportanceColor(i, colors)
              : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : colors.contentTertiary,
          ),
        ),
      ),
    );
  }

  Widget _recurrenceToggle(SkladColors colors, Function(int) onSelect) {
    final labels = ["Разово", "Неделя", "Месяц", "Цикл"];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _tempRecurrenceMode == i
                      ? colors.accentAction
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _tempRecurrenceMode == i
                        ? Colors.white
                        : colors.contentSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reminderChip(
    String time,
    SkladColors colors,
    VoidCallback onDelete,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: colors.accentAction.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: colors.accentAction.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.accentAction,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onDelete,
          child: Icon(
            Icons.close_rounded,
            size: 14,
            color: colors.accentAction,
          ),
        ),
      ],
    ),
  );

  Widget _addTimeButton(
    BuildContext context,
    SkladColors colors,
    bool isDark,
    Function(TimeOfDay) onAdd,
  ) => IconButton(
    onPressed: () => _showCupertinoTimePicker(
      context,
      isDark,
      colors,
      TimeOfDay.now(),
      onAdd,
    ),
    icon: const Icon(Icons.add_circle_outline_rounded),
    color: colors.accentAction,
  );

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    required SkladColors colors,
    String? errorText,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: colors.contentTertiary),
    filled: true,
    fillColor: colors.surfaceContainer,
    errorText: errorText,
    errorStyle: TextStyle(
      color: colors.error,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.accentAction, width: 2),
    ),
  );

  // Fixed Point 4: Better distinction between Yellow and Orange
  Color _getImportanceColor(Importance imp, SkladColors colors) {
    switch (imp) {
      case Importance.low:
        return colors.success;
      case Importance.medium:
        return const Color(0xFFFFD600); // Vibrant Yellow (A400 variant)
      case Importance.high:
        return const Color(0xFFFF6D00); // Deep Orange (A700 variant)
      case Importance.critical:
        return colors.error;
    }
  }

  bool _isDateInXYCycle(DateTime date, DateTime start, int x, int y) {
    final diff = date.difference(start).inDays;
    if (diff < 0) return false;
    return (diff % (x + y)) < x;
  }

  Future<void> _saveTaskToDatabase(Task task) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    final docId = task.id.isEmpty
        ? FirebaseFirestore.instance.collection('tasks').doc().id
        : task.id;
    await FirebaseFirestore.instance.collection('tasks').doc(docId).set({
      'title': task.title,
      'date': task.date.toIso8601String(),
      'reminders': task.reminders
          .map((r) => {'h': r.hour, 'm': r.minute})
          .toList(),
      'isShared': task.isShared,
      'creatorId': uid,
      'creatorName': task.creatorName,
      'creatorPfpUrl': task.creatorPfpUrl,
      'importance': task.importance.index,
      'recurrenceMode': task.recurrenceMode,
      'selectedWeekdays': task.selectedWeekdays.toList(),
      'selectedMonthDays': task.selectedMonthDays.toList(),
      'timestamp': FieldValue.serverTimestamp(),
      'xDays': task.xDays,
      'yDays': task.yDays,
      'cycleStartDate': task.cycleStartDate?.toIso8601String(),
    });
  }

  void _deleteTaskFromFirebase(String id) =>
      FirebaseFirestore.instance.collection('tasks').doc(id).delete();

  Widget _buildEmptyState(SkladColors colors, {bool isSearch = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off_rounded : Icons.event_available_rounded,
            size: 84,
            color: colors.contentTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'Ничего не найдено' : 'Свободный день',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.contentPrimary.withValues(alpha: 0.6),
            ),
          ),
          Text(
            isSearch
                ? 'Попробуйте изменить запрос'
                : 'Задач на выбранную дату нет',
            style: TextStyle(
              color: colors.contentSecondary.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
