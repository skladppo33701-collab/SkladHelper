import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:sklad_helper_33701/core/theme.dart';

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

class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  bool _titleTouched = false;
  int _selectedView = 0; // 0: Personal, 1: Shared
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _taskController = TextEditingController();
  final ScrollController _dateScrollController = ScrollController();

  // --- NEW: Search/List Mode State ---
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();

  int _recurrenceMode = 0;
  final List<TimeOfDay> _selectedReminders = [];
  final Set<int> _selectedWeekdays = {};
  final Set<int> _selectedMonthDays = {};
  int _xDays = 1;
  int _yDays = 1;
  final DateTime _cycleStartDate = DateTime.now();
  bool isSaving = false;

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
      // If we are in search mode, jumping to today should probably exit search mode
      if (_isSearchMode) {
        _isSearchMode = false;
        _searchController.clear();
      }
    });

    if (_dateScrollController.hasClients) {
      _dateScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // --- HELPER: Get Task Subtitle (Date/Recurrence) ---
  String _getTaskSubtitle(Task task) {
    if (task.recurrenceMode == 0) {
      return DateFormat('d MMM yyyy', 'ru').format(task.date);
    } else if (task.recurrenceMode == 1) {
      final days = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"];
      final selected = task.selectedWeekdays.map((i) => days[i]).join(", ");
      return "Еженедельно: $selected";
    } else if (task.recurrenceMode == 2) {
      return "Ежемесячно (числа: ${task.selectedMonthDays.join(', ')})";
    } else if (task.recurrenceMode == 3) {
      return "Цикл: ${task.xDays} раб. / ${task.yDays} вых.";
    }
    return "";
  }

  void _showTaskSheet(BuildContext context, {Task? existingTask}) {
    final userAsync = ref.watch(userRoleProvider);
    if (userAsync.isLoading || userAsync.hasError || userAsync.value == null) {
      return;
    }
    final currentUser = userAsync.value!;

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
    } else {
      _taskController.clear();
      _recurrenceMode = 0;
      _selectedReminders.clear();
      _selectedWeekdays.clear();
      _selectedMonthDays.clear();
      _xDays = 1;
      _yDays = 1;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final proColors = theme.extension<SkladColors>()!;
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final subText = isDark
              ? Colors.white.withValues(alpha: 0.38)
              : const Color(0xFF64748B);

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            child: Container(
              decoration: BoxDecoration(
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
                              color: textColor,
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
                                      _selectedReminders.sort(
                                        (a, b) => (a.hour * 60 + a.minute)
                                            .compareTo(b.hour * 60 + b.minute),
                                      );
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
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
                                      width: 0.5,
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

  // --- TIME PICKER MODAL ---
  Future<void> _showTimePickerModal(
    BuildContext context, {
    required TimeOfDay initialTime,
    required Color accent,
    required bool isDark,
    required ValueChanged<TimeOfDay> onTimeSelected,
  }) async {
    TimeOfDay tempTime = initialTime;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 280 + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Отмена",
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                    Text(
                      "Время",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onTimeSelected(tempTime);
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Готово",
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Localizations(
                  locale: const Locale('ru', 'RU'),
                  delegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: isDark ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: DateTime(
                        2024,
                        1,
                        1,
                        initialTime.hour,
                        initialTime.minute,
                      ),
                      minuteInterval: 1, // FIX: 1-minute steps
                      onDateTimeChanged: (dt) {
                        tempTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _addReminderButton(
    BuildContext context,
    bool isDark,
    Color accent,
    ValueChanged<TimeOfDay> onTimeSelected,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final now = DateTime.now();
        final start = TimeOfDay(
          hour: now.hour,
          minute: (now.minute / 5).round() * 5,
        );
        _showTimePickerModal(
          context,
          initialTime: start,
          isDark: isDark,
          accent: accent,
          onTimeSelected: onTimeSelected,
        );
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

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isTodaySelected =
        _selectedDate.day == now.day &&
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year;

    return Scaffold(
      backgroundColor: proColors.surfaceLow,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "СЕГОДНЯ, ${DateFormat('d MMM', 'ru').format(now).toUpperCase()}",
                          style: TextStyle(
                            color: proColors.neutralGray,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // HEADER: Switches between Title and Search Field
                        _isSearchMode
                            ? TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Поиск задач...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: proColors.neutralGray.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => setState(() {}),
                              )
                            : Text(
                                "План задач",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ],
                    ),
                  ),

                  // ACTION BUTTON: Toggles Search Mode
                  Row(
                    children: [
                      // If not searching and not on today, show "Today" button
                      if (!_isSearchMode && !isTodaySelected)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: TextButton.icon(
                            onPressed: _jumpToToday,
                            style: TextButton.styleFrom(
                              backgroundColor: proColors.accentAction
                                  .withValues(alpha: 0.1),
                              foregroundColor: proColors.accentAction,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.history_rounded, size: 16),
                            label: const Text(
                              "Сегодня",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                      // Search Toggle Button
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
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _isSearchMode
                              ? Colors.redAccent.withValues(alpha: 0.1)
                              : proColors.surfaceHigh,
                          foregroundColor: _isSearchMode
                              ? Colors.redAccent
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // DATE PICKER: Only visible if NOT searching
            if (!_isSearchMode)
              Container(
                height: 110,
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: ListView.builder(
                  controller: _dateScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    final date = DateTime.now().add(Duration(days: index));
                    final isSelected =
                        date.day == _selectedDate.day &&
                        date.month == _selectedDate.month &&
                        date.year == _selectedDate.year;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 64,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? proColors.accentAction
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            width: 0.5,
                            color: isSelected
                                ? Colors.transparent
                                : proColors.neutralGray.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E', 'ru').format(date).toUpperCase(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : proColors.neutralGray,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat(
                                'MMM',
                                'ru',
                              ).format(date).toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : proColors.neutralGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // SWITCHER: Always visible
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    width: 0.5,
                    color: proColors.neutralGray.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    _buildSwitchTab(0, "Личные", proColors),
                    _buildSwitchTab(1, "Общие", proColors),
                  ],
                ),
              ),
            ),

            // TASK LIST
            Expanded(
              child: _buildTaskList(
                proColors.accentAction,
                isDark ? Colors.white : Colors.black,
                proColors.neutralGray,
                isDark ? const Color(0xFF1F2937) : Colors.white,
                isDark,
                proColors,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: proColors.accentAction,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        onPressed: () => _showTaskSheet(context),
      ),
    );
  }

  // --- TRUNCATED HELPERS ---
  Widget _importanceChip(
    Importance imp,
    bool isSelected,
    Color blue,
    bool isDark,
    VoidCallback onTap,
  ) {
    String label;
    Color impColor;
    switch (imp) {
      case Importance.low:
        label = "Низкая";
        impColor = Colors.grey.shade500;
        break;
      case Importance.medium:
        label = "Средняя";
        impColor = const Color(0xFFFFC107);
        break;
      case Importance.high:
        label = "Высокая";
        impColor = const Color(0xFFE65100);
        break;
      case Importance.critical:
        label = "Крит.";
        impColor = const Color(0xFFB71C1C);
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

  Widget _buildSwitchTab(int mode, String label, dynamic proColors) {
    final isSelected = _selectedView == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? proColors.accentAction : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : proColors.neutralGray,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider(bool isDark) => Divider(
    height: 32,
    thickness: 1,
    color: isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05),
  );
  Widget _buildInputLabel(String label, bool isDark) => Padding(
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

  Widget _buildDynamicRecurrenceContent(
    BuildContext context,
    bool isDark,
    Color blue,
    Color text,
    Color subText,
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
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? ColorScheme.dark(
                        primary: blue,
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
            ),
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

  void _editExistingReminder(
    BuildContext context,
    bool isDark,
    Color accent,
    TimeOfDay oldTime,
    StateSetter setSheetState,
  ) {
    _showTimePickerModal(
      context,
      initialTime: oldTime,
      isDark: isDark,
      accent: accent,
      onTimeSelected: (newTime) {
        setSheetState(() {
          int index = _selectedReminders.indexOf(oldTime);
          if (index != -1) {
            _selectedReminders[index] = newTime;
            _selectedReminders.sort(
              (a, b) =>
                  (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
            );
          }
        });
      },
    );
  }

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
          if (onDelete != null)
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

  Widget _typeChip(
    String label,
    bool isSelected,
    Color blue,
    bool isDark,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? blue
            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
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
  Widget _buildMonthDayPicker(
    Color adaptiveBlue,
    bool isDark,
    StateSetter setSheetState,
  ) => Column(
    children: [
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: 31,
        itemBuilder: (context, index) {
          int day = index + 1;
          bool isSelected = _selectedMonthDays.contains(day);
          return GestureDetector(
            onTap: () => setSheetState(
              () => isSelected
                  ? _selectedMonthDays.remove(day)
                  : _selectedMonthDays.add(day),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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
  Widget _buildWeekdayPicker(
    Color adaptiveBlue,
    bool isDark,
    StateSetter setSheetState,
  ) {
    final days = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(days.length, (index) {
          bool isSelected = _selectedWeekdays.contains(index);
          return GestureDetector(
            onTap: () => setSheetState(
              () => isSelected
                  ? _selectedWeekdays.remove(index)
                  : _selectedWeekdays.add(index),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
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
                days[index],
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildXYCycleInput(
    Color blue,
    bool isDark,
    StateSetter setSheetState,
  ) => Row(
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
  Widget _buildSmallNumInput(
    String label,
    int value,
    Function(int) onChanged,
    Color blue,
    bool isDark,
  ) => Column(
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
        cursorColor: blue,
        onChanged: (s) => onChanged(int.tryParse(s) ?? 1),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: _inputDecoration(hint: "$value", isDark: isDark),
      ),
    ],
  );
  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    String? errorText,
  }) => InputDecoration(
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
      ),
    ),
  );
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

  bool _isDateInXYCycle(DateTime date, DateTime startDate, int x, int y) {
    final difference = date.difference(startDate).inDays;
    if (difference < 0) return false;
    final cycleLength = x + y;
    if (cycleLength == 0) return true;
    final dayInCycle = difference % cycleLength;
    return dayInCycle < x;
  }

  Widget _importanceIndicator(
    Importance importance,
    bool isDark,
    SkladColors proColors,
  ) {
    Color indicatorColor;
    switch (importance) {
      case Importance.low:
        indicatorColor = proColors.success;
        break;
      case Importance.medium:
        indicatorColor = proColors.warning;
        break;
      case Importance.high:
      case Importance.critical:
        indicatorColor = proColors.error;
        break;
    }
    return Container(
      width: 4,
      height: 32,
      decoration: BoxDecoration(
        color: indicatorColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // --- BUILD LIST ---
  Widget _buildTaskList(
    Color accent,
    Color text,
    Color subText,
    Color cardBg,
    bool isDark,
    SkladColors proColors,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Ошибка загрузки"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTasks = snapshot.data!.docs
            .map(
              (doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .toList();

        final filteredTasks = allTasks.where((t) {
          bool sameTab = t.isShared == (_selectedView == 1);
          if (!sameTab) return false;

          // --- LOGIC: If Searching, show EVERYTHING that matches query ---
          if (_isSearchMode) {
            if (_searchController.text.isEmpty) {
              return true; // Show all if empty
            }
            return t.title.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
          }

          // --- LOGIC: Normal Mode (Filter by Date) ---
          switch (t.recurrenceMode) {
            case 0:
              return t.date.day == _selectedDate.day &&
                  t.date.month == _selectedDate.month &&
                  t.date.year == _selectedDate.year;
            case 1:
              return t.selectedWeekdays.contains(_selectedDate.weekday - 1);
            case 2:
              return t.selectedMonthDays.contains(_selectedDate.day);
            case 3:
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
              _isSearchMode ? "Ничего не найдено" : 'На этот день задач нет',
              style: TextStyle(color: proColors.neutralGray),
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
                  proColors,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _taskItemCard(
    Task task,
    bool isDark,
    Color text,
    Color subText,
    Color accent,
    SkladColors proColors,
  ) {
    final authState = ref.watch(authProvider);
    final currentUser = authState;
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
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
                // Show Date/Recurrence info if searching, otherwise show reminder
                if (_isSearchMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: subText),
                        const SizedBox(width: 4),
                        Text(
                          _getTaskSubtitle(task),
                          style: GoogleFonts.inter(
                            color: subText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (task.reminders.isNotEmpty) ...[
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
                          task.creatorName == currentUser.name
                              ? "В"
                              : task.creatorName[0],
                          style: TextStyle(color: accent, fontSize: 12),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  task.creatorName == currentUser.name
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

  Widget _buildFixedHeader(bool isDark) => Container(
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
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    ),
  );
}
