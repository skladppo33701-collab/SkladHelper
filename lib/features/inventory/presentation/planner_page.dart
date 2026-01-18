import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  // =============================================================================
  // 1. STATE VARIABLES
  // =============================================================================

  // --- View & Navigation ---
  int _selectedView = 0; // 0: Personal, 1: Shared
  DateTime _selectedDate = DateTime.now();

  // --- Task Input Control ---
  final TextEditingController _taskController = TextEditingController();
  final List<Task> _tasks = [];

  // --- Recurrence & Scheduling ---
  int _recurrenceMode = 0; // 0: Single, 1: Weekly, 2: Monthly, 3: X/Y Cycle
  final List<TimeOfDay> _selectedReminders = [
    const TimeOfDay(hour: 9, minute: 0),
  ];

  // --- Specific Recurrence Data ---
  final Set<int> _selectedWeekdays = {}; // For Mode 1
  final Set<int> _selectedMonthDays = {}; // For Mode 2

  // --- X/Y Cycle Logic Data (For Mode 3) ---
  int _xDays = 1; // Number of active days
  int _yDays = 1; // Number of gap days
  final DateTime _cycleStartDate = DateTime.now(); // The "Day 0" for cycle math

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  // --- 2. THE MAIN TASK MODAL (Handles both Create and Edit) ---
  // ... inside _PlannerPageState ...

  void _showTaskSheet(BuildContext context, {Task? existingTask}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // NEW COLORS: Use Slate Blue instead of deep blue for light mode
    final bgColor = isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final adaptiveBlue = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF475569); // Steel Blue
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white38 : const Color(0xFF64748B);

    // 1. INITIALIZE DATA (Crucial for Edit vs Create logic)
    if (existingTask != null) {
      _taskController.text = existingTask.title;
      _recurrenceMode = existingTask.recurrenceMode;
      _selectedReminders.clear();
      _selectedReminders.addAll(existingTask.reminders);
    } else {
      _taskController.clear();
      _recurrenceMode = 0;
      _selectedReminders.clear();
      _selectedReminders.add(const TimeOfDay(hour: 9, minute: 0));
    }

    // Local state for the sheet's toggle/chips
    Importance localImportance = existingTask?.importance ?? Importance.low;
    bool localIsShared = existingTask?.isShared ?? (_selectedView == 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFixedHeader(isDark),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            existingTask == null
                                ? "Новая задача"
                                : "Редактировать",
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _taskController,
                            cursorColor: adaptiveBlue,
                            style: TextStyle(color: textColor),
                            decoration: _inputDecoration(
                              "Напр: Отчет по складу",
                              isDark,
                            ),
                          ),
                          _buildSectionDivider(isDark),

                          _buildInputLabel("Тип задачи", isDark),
                          Row(
                            children: [
                              _typeChip(
                                "Личная",
                                !localIsShared,
                                adaptiveBlue,
                                isDark,
                                () =>
                                    setSheetState(() => localIsShared = false),
                              ),
                              const SizedBox(width: 12),
                              _typeChip(
                                "Общая",
                                localIsShared,
                                adaptiveBlue,
                                isDark,
                                () => setSheetState(() => localIsShared = true),
                              ),
                            ],
                          ),
                          _buildSectionDivider(isDark),

                          _buildInputLabel("Важность", isDark),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: Importance.values
                                  .map(
                                    (imp) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _importanceChip(
                                        imp,
                                        localImportance == imp,
                                        adaptiveBlue,
                                        isDark,
                                        () => setSheetState(
                                          () => localImportance = imp,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          _buildSectionDivider(isDark),

                          _buildInputLabel("Режим повторения", isDark),
                          _buildRecurrenceToggle(
                            adaptiveBlue,
                            isDark,
                            (mode) =>
                                setSheetState(() => _recurrenceMode = mode),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _buildDynamicRecurrenceContent(
                              context,
                              isDark,
                              adaptiveBlue,
                              textColor,
                              setSheetState,
                            ),
                          ),
                          _buildSectionDivider(isDark),

                          _buildInputLabel("Напоминания", isDark),
                          Row(
                            children: [
                              ..._selectedReminders.map(
                                (time) => _reminderChip(
                                  time.format(context),
                                  adaptiveBlue,
                                  isDark,
                                  onDelete: () => setSheetState(
                                    () => _selectedReminders.remove(time),
                                  ),
                                ),
                              ),
                              _addReminderButton(
                                context,
                                isDark,
                                adaptiveBlue,
                                (newTime) {
                                  setSheetState(() {
                                    if (!_selectedReminders.contains(newTime)) {
                                      _selectedReminders.add(newTime);
                                      _selectedReminders.sort(
                                        (a, b) => a.hour.compareTo(b.hour),
                                      );
                                    }
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 16,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      side: BorderSide(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black12,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: Text(
                                      "Отмена",
                                      style: GoogleFonts.inter(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // FIX: Ensure 'if' statements are enclosed in a block
                                      if (_taskController.text.trim().isEmpty) {
                                        return;
                                      }

                                      // UPDATE PARENT STATE
                                      setState(() {
                                        final newTask = Task(
                                          id:
                                              existingTask?.id ??
                                              DateTime.now().toString(),
                                          title: _taskController.text,
                                          date: _selectedDate,
                                          reminders: List.from(
                                            _selectedReminders,
                                          ),
                                          recurrenceMode: _recurrenceMode,
                                          isShared: localIsShared,
                                          importance: localImportance,
                                          xDays: _xDays,
                                          yDays: _yDays,
                                          cycleStartDate: _cycleStartDate,
                                        );

                                        if (existingTask != null) {
                                          int index = _tasks.indexWhere(
                                            (t) => t.id == existingTask.id,
                                          );
                                          // FIX: Wrap statement in a block to fix 'curly_braces_in_flow_control_structures'
                                          if (index != -1) {
                                            _tasks[index] = newTask;
                                          }
                                        } else {
                                          _tasks.add(newTask);
                                        }
                                      });
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: adaptiveBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      existingTask == null
                                          ? "Создать"
                                          : "Сохранить",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  // SECTION 15: SWIPE ACTIONS
  // --- 3. THE TASK LIST (Date Filtered + Swipe Actions) ---
  Widget _buildTaskList(
    Color accent,
    Color text,
    Color subText,
    Color cardBg,
    bool isDark,
  ) {
    final filteredTasks = _tasks.where((t) {
      // 1. Check if it's the same tab (Personal vs Shared)
      bool sameTab = t.isShared == (_selectedView == 1);
      if (!sameTab) return false;

      // 2. Check date based on recurrence mode
      switch (t.recurrenceMode) {
        case 0: // Single (Разово)
          return t.date.day == _selectedDate.day &&
              t.date.month == _selectedDate.month &&
              t.date.year == _selectedDate.year;
        case 1: // Weekly (Дни недели)
          // Note: DateTime.weekday is 1 (Mon) to 7 (Sun), your index is 0-6
          return _selectedWeekdays.contains(_selectedDate.weekday - 1);
        case 2: // Monthly (Даты)
          return _selectedMonthDays.contains(_selectedDate.day);
        case 3: // Cycle X/Y
          return _isDateInXYCycle(
            _selectedDate,
            t.cycleStartDate ?? _cycleStartDate,
            t.xDays ?? 1,
            t.yDays ?? 1,
          );
        default:
          return false;
      }
    }).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Text("Задач на этот день нет", style: TextStyle(color: subText)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return Slidable(
          key: Key(task.id),
          // Left side swipe (reveals Edit)
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25, // Adjust width of the button
            children: [
              SlidableAction(
                onPressed: (context) =>
                    _showTaskSheet(context, existingTask: task),
                backgroundColor: accent.withValues(alpha: 0.1),
                foregroundColor: accent,
                icon: Icons.edit_note_rounded,
                label: 'Edit',
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(20),
                ),
              ),
            ],
          ),
          // Right side swipe (reveals Delete)
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (context) {
                  setState(() {
                    _tasks.removeWhere((t) => t.id == task.id);
                  });
                },
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                foregroundColor: Colors.redAccent,
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
            ],
          ),
          child: _taskItemCard(task, accent, text, subText, cardBg, isDark),
        );
      },
    );
  }

  // --- 4. CORE UI COMPONENTS (Cards & Chips) ---
  Widget _taskItemCard(
    Task task,
    Color accent,
    Color text,
    Color subText,
    Color cardBg,
    bool isDark,
  ) {
    Color impColor = _getImportanceColor(
      task.importance,
      isDark,
    ); // Pass isDark here
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: impColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Task Title with consistent font
                Text(
                  task.title,
                  style: GoogleFonts.inter(
                    color: text,
                    fontWeight:
                        FontWeight.w600, // Slightly reduced bold for elegance
                    fontSize: 16,
                  ),
                ),

                // 2. Vertical Spacing
                const SizedBox(height: 6),

                // 3. Time Row with Icon (Only show if time exists)
                if (task.reminders.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: subText),
                      const SizedBox(width: 4),
                      Text(
                        task.reminders.first.format(context),
                        style: GoogleFonts.inter(
                          // FIX: Matches title font
                          color: subText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  // Optional: Placeholder or nothing if no time
                  Text(
                    "--:--",
                    style: GoogleFonts.inter(
                      color: subText.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // 4. Shared/Personal Indicator Icon
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(
              task.isShared ? Icons.group_outlined : Icons.person_outline,
              size: 20,
              color: subText.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Color _getImportanceColor(Importance imp, bool isDark) {
    switch (imp) {
      case Importance.low:
        return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      case Importance.medium:
        return const Color(0xFFF59E0B); // Amber/Gold
      case Importance.high:
        return const Color(0xFFEA580C); // Orange
      case Importance.critical:
        return Colors.redAccent;
    }
  }

  // --- 5. PAGE BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final adaptiveBlue = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF1E3A8A);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white38 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildDateTimeline(isDark, adaptiveBlue, textColor, subTextColor),
            _buildCategoryToggle(adaptiveBlue, isDark, cardColor),
            Expanded(
              child: _buildTaskList(
                adaptiveBlue,
                textColor,
                subTextColor,
                cardColor,
                isDark,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: adaptiveBlue,
        onPressed: () => _showTaskSheet(context),
        child: Icon(
          Icons.add,
          color: isDark ? Colors.black : Colors.white,
          size: 28,
        ),
      ),
    );
  }

  // =============================================================================
  // SECTION 1: TOP NAVIGATION & DATE SELECTION
  // =============================================================================

  /// Builds the horizontal scrolling calendar timeline at the top of the page.
  /// Allows users to select a specific day to filter tasks.
  Widget _buildDateTimeline(
    bool isDark,
    Color accent,
    Color text,
    Color subText,
  ) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 365, // Allows scrolling through a full year
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));

          // Exact comparison to ensure only one specific day is selected
          bool isSelected =
              date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;

          String dayName = DateFormat('E', 'ru_RU').format(date).toUpperCase();
          String monthName = DateFormat('MMM', 'ru_RU')
              .format(date)
              .replaceAll('.', '')
              .trim() // ADD THIS to remove hidden spaces
              .toUpperCase();

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 60, // Slightly narrower for a tighter fit
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: isSelected ? 2 : 1,
                  color: isSelected
                      ? accent
                      : (isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05)),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : (!isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : []),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthName.trim(),
                    style: TextStyle(
                      color: isSelected
                          ? (isDark
                                ? Colors.black.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.8))
                          : subText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4), // Added space
                  Text(
                    "${date.day}",
                    style: TextStyle(
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2), // Added space
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected
                          ? (isDark
                                ? Colors.black.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.8))
                          : subText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =============================================================================
  // SECTION 2: CATEGORY TOGGLE (PERSONAL VS SHARED)
  // =============================================================================

  /// Builds the top switch to toggle between Personal tasks and Shared tasks.
  Widget _buildCategoryToggle(Color accent, bool isDark, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        height: 54,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? cardColor : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            // Index 0: Personal (Left)
            _toggleItem("Личные", 0, accent, isDark),
            // Index 1: Shared (Right)
            _toggleItem("Общие", 1, accent, isDark),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // SECTION 2.1: TOGGLE ITEM HELPER
  // =============================================================================

  /// Builds the individual clickable items for the Personal/Shared toggle.
  /// Handles the background animation and text color switching based on state.
  Widget _toggleItem(String title, int index, Color accent, bool isDark) {
    bool isActive = _selectedView == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // SECTION 3: FORM ELEMENTS & INPUT DECORATION
  // =============================================================================

  /// Builds the small "handle" at the top of the bottom sheet.
  Widget _buildFixedHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black12,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    );
  }

  /// Builds a small, bold label above input fields.
  Widget _buildInputLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.4),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Standard decoration for text input fields in the planner.
  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.2),
        fontSize: 14,
      ),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // =============================================================================
  // SECTION 4: RECURRENCE & SELECTION LOGIC
  // =============================================================================

  Widget _buildRecurrenceToggle(
    Color accent,
    bool isDark,
    Function(int) onSelect,
  ) {
    final labels = ["Разово", "Дни недели", "Даты", "Цикл X/Y"];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          bool active = _recurrenceMode == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: active ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: active
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white38 : Colors.black45),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // =============================================================================
  // SECTION 5: SWIPE ACTIONS
  // =============================================================================

  // /// Builds the background UI revealed when swiping a task list item.
  // Widget _buildSwipeAction(IconData icon, Color color, Alignment alignment) {
  //   return Container(
  //     alignment: alignment,
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     margin: const EdgeInsets.symmetric(vertical: 8),
  //     decoration: BoxDecoration(
  //       color: color,
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: Icon(icon, color: Colors.white),
  //   );
  // }

  // =============================================================================
  // SECTION 6: REMINDERS & CHIPS
  // =============================================================================

  /// Builds a removable chip showing a selected reminder time.
  Widget _reminderChip(
    String time,
    Color accent,
    bool isDark, {
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: TextStyle(
              color: isDark ? Colors.white : accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: isDark ? Colors.white70 : accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the '+' button that opens the Cupertino time picker modal.
  Widget _addReminderButton(
    BuildContext context,
    bool isDark,
    Color accent,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        TimeOfDay pickedTime = const TimeOfDay(hour: 9, minute: 0);

        // Using showModalBottomSheet instead of showCupertinoModalPopup
        // to support the 'enableDrag' and 'isScrollControlled' features
        // seen in your main task page.
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          enableDrag: true, // Enables dragging down from the handle or content
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: 350 + MediaQuery.of(context).padding.bottom,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // 1. THE DRAG HANDLE
                // Moving it here and making it part of the column allows it
                // to act as a physical "grab" point for the modal.
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: Text(
                          "Отмена",
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        "Время",
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      CupertinoButton(
                        child: Text(
                          "Готово",
                          style: GoogleFonts.inter(
                            color: accent, // Your dynamic Importance color
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: () {
                          onTimeSelected(pickedTime);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // 2. THE PICKER
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: isDark ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: GoogleFonts.inter(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: DateTime(2024, 1, 1, 9, 0),
                      onDateTimeChanged: (DateTime newDate) {
                        pickedTime = TimeOfDay(
                          hour: newDate.hour,
                          minute: newDate.minute,
                        );
                      },
                    ),
                  ),
                ),
                // Bottom Safe Area padding
                SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, color: accent, size: 20),
      ),
    );
  }
  // =============================================================================
  // SECTION 7: TASK PROPERTY SELECTORS (SHARED & IMPORTANCE)
  // =============================================================================

  /// Builds the chip to choose between Personal and Shared task types.
  Widget _typeChip(
    String label,
    bool isSelected,
    Color blue,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? blue
              : (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // UPDATED SECTION 8: IMPORTANCE CHIPS (FIXED COLORS)
  // =============================================================================

  Widget _importanceChip(
    Importance imp,
    bool isSelected,
    Color blue,
    bool isDark,
    VoidCallback onTap,
  ) {
    String label;
    Color impColor;

    // ADJUSTED COLORS: Medium is now Cyan to prevent blending
    switch (imp) {
      case Importance.low:
        label = "Низкая";
        impColor = Colors.grey;
        break;
      case Importance.medium:
        label = "Средняя";
        impColor = const Color(0xFFF59E0B);
        break;
      case Importance.high:
        label = "Высокая";
        impColor = Colors.orange;
        break;
      case Importance.critical:
        label = "Крит.";
        impColor = Colors.red;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? impColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? impColor
                : (isDark ? Colors.white24 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // SECTION 9: MODAL LAYOUT HELPERS
  // =============================================================================

  /// Switches the input UI based on the recurrence mode (Calendar, Weekdays, or Month Days).
  Widget _buildDynamicRecurrenceContent(
    BuildContext context,
    bool isDark,
    Color blue,
    Color text,
    StateSetter setSheetState,
  ) {
    if (_recurrenceMode == 0) {
      return GestureDetector(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            locale: const Locale('ru', 'RU'),
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2050),
          );
          if (picked != null) setSheetState(() => _selectedDate = picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: blue),
              const SizedBox(width: 12),
              Text(
                DateFormat('d MMMM, yyyy', 'ru_RU').format(_selectedDate),
                style: TextStyle(color: text, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    } else if (_recurrenceMode == 1) {
      return _buildWeekdayPicker(blue, isDark, setSheetState);
    } else if (_recurrenceMode == 2) {
      return _buildMonthDayPicker(blue, isDark, setSheetState);
    } else {
      // FIX: Pass the state setter and blue color
      return _buildXYCycleInput(blue, isDark, setSheetState);
    }
  }

  // =============================================================================
  // SECTION 10: UI DIVIDERS & SEPARATORS
  // =============================================================================
  Widget _buildSectionDivider(bool isDark) {
    return Divider(
      height: 32,
      thickness: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05),
    );
  }

  // =============================================================================
  // SECTION 11: ADVANCED DATE PICKERS (MONTH DAYS)
  // =============================================================================
  Widget _buildMonthDayPicker(
    Color adaptiveBlue,
    bool isDark,
    StateSetter setSheetState,
  ) {
    return Column(
      children: [
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10, // Symmetrical
            childAspectRatio: 1,
          ),
          itemCount: 31,
          itemBuilder: (context, index) {
            int day = index + 1;
            bool isSelected = _selectedMonthDays.contains(day);
            return GestureDetector(
              onTap: () => setSheetState(() {
                isSelected
                    ? _selectedMonthDays.remove(day)
                    : _selectedMonthDays.add(day);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? adaptiveBlue
                      : (isDark
                            ? Colors.white10
                            : Colors.black12.withValues(alpha: 0.03)),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$day",
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // =============================================================================
  // SECTION 12: RECURRENCE - WEEKDAY PICKER
  // =============================================================================
  Widget _buildWeekdayPicker(
    Color adaptiveBlue,
    bool isDark,
    StateSetter setSheetState,
  ) {
    final days = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // FIX: Full-width alignment
        children: List.generate(days.length, (index) {
          bool isSelected = _selectedWeekdays.contains(index);
          return GestureDetector(
            onTap: () => setSheetState(() {
              isSelected
                  ? _selectedWeekdays.remove(index)
                  : _selectedWeekdays.add(index);
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42, // Fixed size for perfect circles
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // FIX: Selection is blue, unselected is subtle
                color: isSelected
                    ? adaptiveBlue
                    : (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.03)),
                shape: BoxShape.circle,
              ),
              child: Text(
                days[index],
                style: GoogleFonts.inter(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // =============================================================================
  // SECTION 13: RECURRENCE - X/Y CYCLE INPUT
  // =============================================================================
  Widget _buildXYCycleInput(
    Color blue,
    bool isDark,
    StateSetter setSheetState,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSmallNumInput(
            "Активно (X)",
            _xDays,
            (val) => setSheetState(() => _xDays = val),
            blue,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSmallNumInput(
            "Перерыв (Y)",
            _yDays,
            (val) => setSheetState(() => _yDays = val),
            blue,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallNumInput(
    String label,
    int value,
    Function(int) onChanged,
    Color blue,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          keyboardType: TextInputType.number,
          cursorColor: blue, // FIX: Carrot is now blue
          onChanged: (s) => onChanged(int.tryParse(s) ?? 1),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: _inputDecoration("$value", isDark),
        ),
      ],
    );
  }

  // =============================================================================
  // SECTION 14: XY CYCLE MATHEMATICAL LOGIC
  // =============================================================================
  /// Checks if a specific [date] is an "active" day based on an X/Y rhythm.
  bool _isDateInXYCycle(DateTime date, DateTime startDate, int x, int y) {
    // 1. Calculate the total days elapsed since the cycle's birth date
    // We use .difference().inDays to get the absolute count of midnights passed
    final difference = date.difference(startDate).inDays;

    // 2. If the date being checked is before the cycle started, it's inactive
    if (difference < 0) return false;

    // 3. The length of one complete period is the sum of Active (X) + Break (Y)
    final cycleLength = x + y;

    // 4. Safety check: avoid division by zero if input is somehow 0
    if (cycleLength == 0) return true;

    // 5. Use the Modulo operator (%) to find the remainder.
    // This tells us exactly which "day" of the cycle we are on.
    final dayInCycle = difference % cycleLength;

    // 6. If the current position is less than X, the task is active today.
    // Example: If X=3, Y=2. Days 0,1,2 are active. Day 3,4 are break.
    return dayInCycle < x;
  }
}

enum Importance { low, medium, high, critical }

class Task {
  final String id;
  final String title;
  final DateTime date;
  final List<TimeOfDay> reminders;
  final int recurrenceMode;
  final bool isShared;
  final Importance importance;

  // Data for Cycle X/Y
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
    this.xDays,
    this.yDays,
    this.cycleStartDate,
  });
}
