import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:sklad_helper_33701/core/theme.dart';

class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  // =============================================================================
  // 1. STATE VARIABLES
  // =============================================================================
  bool _titleTouched = false;
  // --- View & Navigation ---
  int _selectedView = 0; // 0: Personal, 1: Shared
  DateTime _selectedDate = DateTime.now();
  // --- Task Input Control ---
  final TextEditingController _taskController = TextEditingController();

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
  final ScrollController _dateController = ScrollController();
  bool isSaving = false;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  // --- 2. THE MAIN TASK MODAL (Handles both Create and Edit) ---
  void _showTaskSheet(BuildContext context, {Task? existingTask}) {
    final userAsync = ref.watch(userRoleProvider);

    if (userAsync.isLoading || userAsync.hasError || userAsync.value == null) {
      return;
    }

    final currentUser = userAsync.value!;

    // Logic variables
    Importance localImportance = existingTask?.importance ?? Importance.low;
    bool localIsShared = existingTask?.isShared ?? (_selectedView == 1);

    if (existingTask != null) {
      _taskController.text = existingTask.title;
      _recurrenceMode = existingTask.recurrenceMode;
      _selectedReminders
        ..clear()
        ..addAll(existingTask.reminders);
      _selectedDate = existingTask.date;
      _selectedWeekdays
        ..clear()
        ..addAll(existingTask.selectedWeekdays);
      _selectedMonthDays
        ..clear()
        ..addAll(existingTask.selectedMonthDays);
      _xDays = existingTask.xDays ?? 1;
      _yDays = existingTask.yDays ?? 1;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          // --- DEFINITIONS INSIDE BUILDER (Fixes 'Undefined name' errors) ---
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final proColors = theme.extension<SkladColors>()!;
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final subText = isDark
              ? Colors.white.withValues(alpha: 0.38)
              : const Color(0xFF64748B);
          // ------------------------------------------------------------------

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            child: Container(
              decoration: BoxDecoration(
                // FIX: Use theme color instead of undefined 'bgColor'
                color: theme.scaffoldBackgroundColor,
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            existingTask == null
                                ? "Новая задача"
                                : "Редактировать задачу",
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color:
                                  textColor, // Uses the variable defined above
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _taskController,
                            cursorColor: proColors.accentAction,
                            style: TextStyle(color: textColor),
                            onChanged: (_) => setSheetState(() {}),
                            onTap: () =>
                                setSheetState(() => _titleTouched = true),
                            decoration: _inputDecoration(
                              hint: 'Например: Отчет по складу',
                              isDark: isDark,
                              errorText:
                                  (_titleTouched &&
                                      _taskController.text.trim().isEmpty)
                                  ? 'Обязательно укажите название задачи'
                                  : null,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          _buildSectionDivider(isDark),

                          _buildInputLabel("Тип задачи", isDark),
                          Row(
                            children: [
                              _typeChip(
                                "Личная",
                                !localIsShared,
                                proColors.accentAction,
                                isDark,
                                () =>
                                    setSheetState(() => localIsShared = false),
                              ),
                              const SizedBox(width: 12),
                              _typeChip(
                                "Общая",
                                localIsShared,
                                proColors.accentAction,
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
                                        proColors.accentAction,
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
                            proColors.accentAction,
                            isDark,
                            (mode) =>
                                setSheetState(() => _recurrenceMode = mode),
                          ),

                          const SizedBox(height: 12),

                          _buildDynamicRecurrenceContent(
                            context,
                            isDark,
                            proColors.accentAction,
                            textColor,
                            subText,
                            setSheetState,
                          ),

                          _buildSectionDivider(isDark),

                          _buildInputLabel("Напоминания", isDark),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._selectedReminders.map(
                                (time) => GestureDetector(
                                  onTap: () => _editExistingReminder(
                                    context,
                                    isDark,
                                    proColors.accentAction,
                                    time,
                                    setSheetState,
                                  ),
                                  child: _reminderChip(
                                    time.format(context),
                                    proColors.accentAction,
                                    isDark,
                                    onDelete: () => setSheetState(
                                      () => _selectedReminders.remove(time),
                                    ),
                                  ),
                                ),
                              ),
                              _addReminderButton(
                                context,
                                isDark,
                                proColors.accentAction,
                                (newTime) {
                                  setSheetState(() {
                                    if (!_selectedReminders.contains(newTime)) {
                                      _selectedReminders.add(newTime);
                                      _selectedReminders.sort((a, b) {
                                        final ma = a.hour * 60 + a.minute;
                                        final mb = b.hour * 60 + b.minute;
                                        return ma.compareTo(mb);
                                      });
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // --- SAVE BUTTON LOGIC (Fixed) ---
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black12,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
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
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          final title = _taskController.text
                                              .trim();
                                          if (title.isEmpty) {
                                            setSheetState(
                                              () => _titleTouched = true,
                                            );
                                            return;
                                          }

                                          setSheetState(() => isSaving = true);
                                          try {
                                            final newTask = Task(
                                              id:
                                                  existingTask?.id ??
                                                  FirebaseFirestore.instance
                                                      .collection('tasks')
                                                      .doc()
                                                      .id,
                                              title: title,
                                              date: _selectedDate,
                                              reminders: List.unmodifiable(
                                                _selectedReminders,
                                              ),
                                              recurrenceMode: _recurrenceMode,
                                              isShared: localIsShared,
                                              importance: localImportance,
                                              creatorName: currentUser.name,
                                              creatorPfpUrl:
                                                  currentUser.photoUrl,
                                              selectedWeekdays: {
                                                ..._selectedWeekdays,
                                              },
                                              selectedMonthDays: {
                                                ..._selectedMonthDays,
                                              },
                                              xDays: _xDays,
                                              yDays: _yDays,
                                              cycleStartDate: _cycleStartDate,
                                            );

                                            await _saveTaskToDatabase(newTask);

                                            if (!context.mounted) return;
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Задача сохранена",
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            if (context.mounted) {
                                              _showError("Ошибка: $e");
                                            }
                                          } finally {
                                            if (mounted) {
                                              setSheetState(
                                                () => isSaving = false,
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: proColors.accentAction,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
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
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 16,
                          ),
                        ],
                      ),
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

  // SECTION 15: SWIPE ACTIONS
  // --- 3. THE TASK LIST (Date Filtered + Swipe Actions) ---
  Widget _buildTaskList(
    Color accent,
    Color text,
    Color subText,
    Color cardBg,
    bool isDark,
    SkladColors proColors, // Added parameter
  ) {
    // 1. Get real-time data from Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Ошибка загрузки"));
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Map Firebase docs to Task objects
        final allTasks = snapshot.data!.docs.map((doc) {
          return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // 3. Filter the tasks logic correctly
        final filteredTasks = allTasks.where((t) {
          bool sameTab = t.isShared == (_selectedView == 1);
          if (!sameTab) return false;

          // Filter by Date & Recurrence
          switch (t.recurrenceMode) {
            case 0: // Single
              return t.date.day == _selectedDate.day &&
                  t.date.month == _selectedDate.month &&
                  t.date.year == _selectedDate.year;
            case 1: // Weekly
              // FIX: Check task's own weekdays, not the global state
              return t.selectedWeekdays.contains(_selectedDate.weekday - 1);
            case 2: // Monthly
              // FIX: Check task's own month days
              return t.selectedMonthDays.contains(_selectedDate.day);
            case 3: // Cycle X/Y
              return _isDateInXYCycle(
                _selectedDate,
                t.cycleStartDate ?? _selectedDate,
                t.xDays ?? 1,
                t.yDays ?? 1,
              );
            default:
              return false;
          }
        }).toList();

        if (filteredTasks.isEmpty) {
          return Center(
            child: Text(
              "На этот день ничего не запланировано",
              style: TextStyle(color: subText),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Slidable(
                key: Key(task.id),
                startActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (context) =>
                          _showTaskSheet(context, existingTask: task),
                      backgroundColor: accent.withValues(alpha: 0.1),
                      foregroundColor: accent,
                      icon: Icons.edit_note_rounded,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20),
                      ),
                    ),
                  ],
                ),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (context) => _deleteTaskFromFirebase(task.id),
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                      foregroundColor: Colors.redAccent,
                      icon: Icons.delete_outline_rounded,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(20),
                      ),
                    ),
                  ],
                ),
                child: _taskItemCard(
                  task,
                  isDark,
                  text,
                  subText,
                  accent,
                  proColors, // ADD THIS: Pass the theme extension here
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 4. CORE UI COMPONENTS (Cards & Chips) ---

  // Change the definition to accept SkladColors
  Widget _taskItemCard(
    Task task,
    bool isDark,
    Color text,
    Color subText,
    Color accent,
    SkladColors proColors, // ADD THIS: New parameter
  ) {
    final authState = ref.watch(authProvider);
    final currentUser = authState;

    // Use the theme extension instead of hardcoded hexes
    final cardBg = proColors.surfaceHigh;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        // REMOVE 'const' here
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          _importanceIndicator(task.importance, isDark, proColors),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.inter(
                    color: text,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (task.reminders.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.alarm, size: 12, color: subText),
                      const SizedBox(width: 4),
                      Text(
                        task.reminders.first.format(context),
                        style: GoogleFonts.inter(color: subText, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (task.isShared)
            Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: accent.withValues(alpha: 0.1),
                  backgroundImage:
                      (task.creatorPfpUrl != null &&
                          task.creatorPfpUrl!.isNotEmpty)
                      ? NetworkImage(task.creatorPfpUrl!)
                      : null,
                  child:
                      (task.creatorPfpUrl == null ||
                          task.creatorPfpUrl!.isEmpty)
                      ? Text(
                          task.creatorName == (currentUser.name)
                              ? "В"
                              : task.creatorName[0],
                          style: TextStyle(color: accent, fontSize: 12),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  task.creatorName == (currentUser.name)
                      ? "Вы"
                      : task.creatorName,
                  style: GoogleFonts.inter(color: subText, fontSize: 10),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getImportanceColor(Importance imp, SkladColors proColors) {
    switch (imp) {
      case Importance.low:
        return Colors.grey.shade500;
      case Importance.medium:
        return proColors.warning;
      case Importance.high:
        return proColors.error.withValues(alpha: 0.7);
      case Importance.critical:
        return proColors.error;
    }
  }

  // --- 5. PAGE BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userRoleProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF020617),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      ),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text("Ошибка загрузки профиля: $err"))),
      data: (currentUserRole) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final proColors = theme.extension<SkladColors>()!;

        // Define text colors here so they are available for the whole screen
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subTextColor = isDark
            ? Colors.white.withValues(alpha: 0.38)
            : const Color(0xFF64748B);

        return Scaffold(
          // FIX: Use theme color instead of undefined 'bgColor'
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildDateTimeline(
                  isDark,
                  proColors.accentAction,
                  textColor,
                  subTextColor,
                ),
                _buildCategoryToggle(
                  proColors.accentAction,
                  isDark,
                  proColors.surfaceHigh,
                ),
                Expanded(
                  child: _buildTaskList(
                    proColors.accentAction,
                    textColor,
                    subTextColor,
                    proColors.surfaceHigh,
                    isDark,
                    proColors,
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: proColors.accentAction,
            onPressed: () => _showTaskSheet(context),
            child: Icon(
              Icons.add,
              color: isDark ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
        );
      },
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fixed: More meaningful header layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ваше расписание",
                    style: GoogleFonts.inter(
                      color: subText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'LLLL yyyy',
                      'ru_RU',
                    ).format(_selectedDate).toUpperCase(),
                    style: GoogleFonts.inter(
                      color: text,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  _dateController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                  setState(() => _selectedDate = DateTime.now());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Сегодня",
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            controller: _dateController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 365,
            itemBuilder: (context, index) {
              DateTime date = DateTime.now().add(Duration(days: index));

              // 1. USE 'isSelected' to fix the warning
              bool isSelected = DateUtils.isSameDay(date, _selectedDate);

              String dayName = DateFormat(
                'E',
                'ru_RU',
              ).format(date).toUpperCase();
              String monthName = DateFormat(
                'MMM',
                'ru_RU',
              ).format(date).replaceAll('.', '').trim().toUpperCase();

              // 2. RETURN the widget to fix the 'nullable return' error
              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 60,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    // Apply common border style here
                    border: Border.all(
                      width: isSelected ? 2 : 1,
                      color: isSelected
                          ? accent
                          : (isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        monthName,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : subText,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                      Text(
                        dayName,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
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
        ),
      ],
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
          border: _commonBorder(isDark), // Added this line
        ),
        child: Row(
          children: [
            _toggleItem("Личные", 0, accent, isDark),
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
  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
      errorText: errorText,
      errorStyle: const TextStyle(color: Colors.redAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF475569),
        ), // Use adaptiveBlue here too for consistency
      ),
      // Add fillColor or other styles if needed
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
    ValueChanged<TimeOfDay> onTimeSelected,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        // Nice UX: start from current time rounded to nearest 5 minutes
        final initialTime = TimeOfDay(
          hour: now.hour,
          minute: (now.minute / 5).round() * 5,
        );

        TimeOfDay? selectedTime = await showModalBottomSheet<TimeOfDay>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            TimeOfDay tempTime = initialTime; // local mutable copy

            return Container(
              height: 340 + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header with Cancel / Done
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Отмена',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          'Время напоминания',
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, tempTime);
                          },
                          child: Text(
                            'Готово',
                            style: GoogleFonts.inter(
                              color: accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Time picker
                  Expanded(
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: isDark ? Brightness.dark : Brightness.light,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: true,
                        initialDateTime: DateTime(
                          2000,
                          1,
                          1,
                          initialTime.hour,
                          initialTime.minute,
                        ),
                        minuteInterval: 5, // nicer UX: steps of 5 min
                        onDateTimeChanged: (DateTime dt) {
                          tempTime = TimeOfDay(
                            hour: dt.hour,
                            minute: dt.minute,
                          );
                        },
                      ),
                    ),
                  ),

                  // Extra bottom padding
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );

        if (selectedTime != null) {
          // Optional: small haptic feedback (iOS/Android)
          // HapticFeedback.lightImpact(); // uncomment if you want

          onTimeSelected(selectedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add_rounded, color: accent, size: 22),
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
        impColor = Colors.grey.shade500; // Neutral Grey
        break;
      case Importance.medium:
        label = "Средняя";
        impColor = const Color(0xFFFFC107); // Pure Amber (Bright/Light)
        break;
      case Importance.high:
        label = "Высокая";
        impColor = const Color(0xFFE65100); // Burnt Orange (Dark/Deep)
        break;
      case Importance.critical:
        label = "Крит.";
        impColor = const Color(0xFFB71C1C); // Deep Blood Red (Very Dark)
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
    Color subText, // Add this line
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
            // FIX: Removes purple color and applies your adaptive blue
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: isDark
                      ? ColorScheme.dark(
                          primary: blue, // Your adaptive blue
                          onPrimary: Colors.black,
                          surface: const Color(0xFF1F2937),
                          onSurface: Colors.white,
                        )
                      : ColorScheme.light(
                          primary: blue,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(foregroundColor: blue),
                  ),
                ),
                child: child!,
              );
            },
          );
          // Use the local setSheetState to update the modal UI immediately
          if (picked != null) {
            setSheetState(() => _selectedDate = picked);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: blue),
              const SizedBox(width: 12),
              Text(
                DateFormat('d MMMM, yyyy', 'ru_RU').format(_selectedDate),
                style: GoogleFonts.inter(
                  // Using consistent font
                  color: text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: subText.withValues(alpha: 0.3),
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
                width: 42, // Match this to the weekday circle size
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? adaptiveBlue
                      : (isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.03)),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$day",
                  style: GoogleFonts.inter(
                    fontSize: 13, // Standardized
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
                  fontSize: 10, // Standardized
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
          decoration: _inputDecoration(hint: "$value", isDark: isDark),
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

  // Little helper to reduce redundance
  Border _commonBorder(bool isDark) => Border.all(
    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
    width: 1,
  );
  // Edit reminder helper
  void _editExistingReminder(
    BuildContext context,
    bool isDark,
    Color accent,
    TimeOfDay oldTime,
    StateSetter setSheetState,
  ) {
    // We reuse the logic from _addReminderButton to show the time picker
    _addReminderButton(context, isDark, accent, (newTime) {
      setSheetState(() {
        int index = _selectedReminders.indexOf(oldTime);
        if (index != -1) {
          // Update the time and re-sort to keep them in order
          _selectedReminders[index] = newTime;
          _selectedReminders.sort((a, b) {
            final minutesA = a.hour * 60 + a.minute;
            final minutesB = b.hour * 60 + b.minute;
            return minutesA.compareTo(minutesB);
          });
        }
      });
    });
  }

  // sdfds
  Widget _importanceIndicator(
    Importance importance,
    bool isDark,
    SkladColors proColors,
  ) {
    return Container(
      width: 4,
      height: 32,
      decoration: BoxDecoration(
        color: _getImportanceColor(importance, proColors),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Future<void> _saveTaskToDatabase(Task task) async {
    await FirebaseFirestore.instance.collection('tasks').doc(task.id).set({
      'title': task.title,
      'date': task.date.toIso8601String(),
      'reminders': task.reminders
          .map((r) => {'h': r.hour, 'm': r.minute})
          .toList(),
      'isShared': task.isShared,
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

  // sldf
  void _deleteTaskFromFirebase(String id) {
    FirebaseFirestore.instance.collection('tasks').doc(id).delete();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  // This fixes the 'fromMap' error
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
