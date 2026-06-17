import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/theme/theme_extenstions.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/pages/entry/diary_entry.dart';
import 'package:routine/features/diary/presentation/pages/favorites/diary_favorites_screen.dart.dart';
import 'package:routine/features/diary/presentation/pages/preview/diary_preview.dart';
import 'package:table_calendar/table_calendar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class DiaryCalendarScreen extends StatefulWidget {
  const DiaryCalendarScreen({super.key});

  @override
  State<DiaryCalendarScreen> createState() => _DiaryCalendarScreenState();
}

class _DiaryCalendarScreenState extends State<DiaryCalendarScreen>
    with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late AnimationController _entryListController;
  late Animation<double> _entryListFade;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    _entryListController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _entryListFade = CurvedAnimation(
      parent: _entryListController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _entryListController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  List<DiaryEntryModel> _getEntriesForDay(
    DateTime day,
    List<DiaryEntryModel> allEntries,
  ) {
    final norm = _normalizeDate(day);
    return allEntries.where((e) {
      final d = DateTime.tryParse(e.date) ?? DateTime.now();
      return _normalizeDate(d) == norm;
    }).toList();
  }

  Set<DateTime> _calculateMarkedDates(List<DiaryEntryModel> entries) {
    return entries.map((e) {
      final d = DateTime.tryParse(e.date) ?? DateTime.now();
      return _normalizeDate(d);
    }).toSet();
  }

  bool _dayHasFavorite(DateTime day, List<DiaryEntryModel> entries) {
    return entries.any((e) {
      final d = DateTime.tryParse(e.date) ?? DateTime.now();
      return _normalizeDate(d) == _normalizeDate(day) && e.isFavorite;
    });
  }

  /// Returns the first (non-empty) mood emoji for the given day, or ''.
  String _moodForDay(DateTime day, List<DiaryEntryModel> entries) {
    for (final e in entries) {
      final d = DateTime.tryParse(e.date) ?? DateTime.now();
      if (_normalizeDate(d) == _normalizeDate(day) && e.mood.isNotEmpty) {
        return e.mood;
      }
    }
    return '';
  }

  String _monthName(int m) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m - 1];

  String _shortMonth(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  String _dayName(int wd) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][wd - 1];

  String _formatEntryTime(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
      _focusedDay = day;
    });
    _entryListController
      ..reset()
      ..forward();
  }

  void _navigateToEntry(DiaryEntryModel entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DiaryPreviewScreen(entryId: entry.id)),
    );
    if (mounted) context.read<DiaryBloc>().add(LoadDiaryEntries());
  }

  void _goToFavorites() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const DiaryFavoritesScreen(),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  // ── Day cell builder ───────────────────────────────────────────────────────

  Widget _buildDayCell({
    required BuildContext context,
    required DateTime day,
    required List<DiaryEntryModel> entries,
    required Set<DateTime> markedDates,
    required bool isToday,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final norm = _normalizeDate(day);
    final hasEntry = markedDates.contains(norm);
    final hasFav = _dayHasFavorite(day, entries);
    final mood = _moodForDay(day, entries);

    // ── Selected ────────────────────────────────────────────────────────────
    if (isSelected) {
      return _SelectedDayCell(
        day: day,
        hasFav: hasFav,
        mood: mood,
        hasEntry: hasEntry,
        theme: theme,
      );
    }

    // ── Favorite ────────────────────────────────────────────────────────────
    if (hasFav) {
      return _FavoriteDayCell(day: day, mood: mood, theme: theme);
    }

    // ── Has entry ────────────────────────────────────────────────────────────
    if (hasEntry) {
      return _EntryDayCell(day: day, mood: mood, theme: theme);
    }

    // ── Today (no entry) ─────────────────────────────────────────────────────
    if (isToday) {
      return _TodayEmptyCell(day: day, theme: theme);
    }

    // ── Default ──────────────────────────────────────────────────────────────
    return Center(
      child: Text(
        '${day.day}',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgImagePath =
        Theme.of(context).extension<BackgroundImageTheme>()?.imagePath ??
        'assets/img/themes/theme_1.png';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<DiaryBloc, DiaryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return _ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<DiaryBloc>().add(LoadDiaryEntries()),
            );
          }

          final entries = state.entries;
          final markedDates = _calculateMarkedDates(entries);
          final dayEntries = _selectedDay != null
              ? _getEntriesForDay(_selectedDay!, entries)
              : <DiaryEntryModel>[];
          final favCount = entries.where((e) => e.isFavorite).length;
          final selectedDay = _selectedDay ?? DateTime.now();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero SliverAppBar ────────────────────────────────────
              SliverAppBar(
                pinned: true,
                expandedHeight: 200,
                collapsedHeight: 60,
                stretch: true,
                backgroundColor: theme.colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final expandRatio =
                        ((constraints.maxHeight - 60) / (200 - 60)).clamp(
                          0.0,
                          1.0,
                        );
                    final isCollapsed = expandRatio < 0.15;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Opacity(
                          opacity: expandRatio,
                          child: Image.asset(bgImagePath, fit: BoxFit.cover),
                        ),
                        Opacity(
                          opacity: expandRatio,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.fromARGB(57, 0, 0, 0),
                                  Color.fromARGB(78, 0, 0, 0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Collapsed bar
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            bottom: false,
                            child: SizedBox(
                              height: 60,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        CupertinoIcons.back,
                                        size: 20,
                                        color: isCollapsed
                                            ? theme.colorScheme.onSurface
                                            : Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    Expanded(
                                      child: AnimatedOpacity(
                                        opacity: isCollapsed ? 1.0 : 0.0,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Text(
                                          '${_monthName(_focusedDay.month)} ${_focusedDay.year}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    _IconPill(
                                      onTap: _goToFavorites,
                                      color: Colors.redAccent,
                                      icon: Icons.favorite,
                                      label: '$favCount',
                                      textColor: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Expanded hero content
                        Positioned(
                          bottom: 0,
                          left: 20,
                          right: 20,
                          child: Opacity(
                            opacity: expandRatio,
                            child: SafeArea(
                              top: false,
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 20,
                                  top: 52,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _monthName(_focusedDay.month),
                                            style: theme.textTheme.displaySmall
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: -1,
                                                  height: 1,
                                                ),
                                          ),
                                          Text(
                                            '${_focusedDay.year}',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.55),
                                                  fontWeight: FontWeight.w300,
                                                  letterSpacing: 2,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _StatPill(
                                          icon: Icons.book_outlined,
                                          label: '${entries.length} entries',
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 6),
                                        _StatPill(
                                          icon: Icons.favorite,
                                          label: '$favCount favorites',
                                          color: Colors.redAccent.shade100,
                                          iconColor: Colors.redAccent,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Calendar card ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                    child: TableCalendar(
                      availableGestures: AvailableGestures.horizontalSwipe,
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                      onDaySelected: (sel, foc) {
                        _onDaySelected(sel);
                      },
                      onPageChanged: (foc) => setState(() => _focusedDay = foc),
                      // Give each row enough height for the emoji + ring cell
                      rowHeight: 52,
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                        isTodayHighlighted: false, // we handle this ourselves
                        markersMaxCount: 0, // we handle markers ourselves
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: theme.textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                        leftChevronIcon: _CalChevron(
                          icon: Icons.chevron_left,
                          color: theme.colorScheme.primary,
                        ),
                        rightChevronIcon: _CalChevron(
                          icon: Icons.chevron_right,
                          color: theme.colorScheme.primary,
                        ),
                        headerPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: theme.textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        weekendStyle: theme.textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        // Route every visible cell through our custom builder
                        defaultBuilder: (ctx, day, _) => _buildDayCell(
                          context: ctx,
                          day: day,
                          entries: entries,
                          markedDates: markedDates,
                          isToday: isSameDay(day, DateTime.now()),
                          isSelected: isSameDay(_selectedDay, day),
                        ),
                        todayBuilder: (ctx, day, _) => _buildDayCell(
                          context: ctx,
                          day: day,
                          entries: entries,
                          markedDates: markedDates,
                          isToday: true,
                          isSelected: isSameDay(_selectedDay, day),
                        ),
                        selectedBuilder: (ctx, day, _) => _buildDayCell(
                          context: ctx,
                          day: day,
                          entries: entries,
                          markedDates: markedDates,
                          isToday: isSameDay(day, DateTime.now()),
                          isSelected: true,
                        ),
                        // No marker builder — decoration is inside the cell itself
                      ),
                    ),
                  ),
                ),
              ),

              // ── Legend ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      _LegendItem(
                        label: 'Has entry',
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                                theme.colorScheme.secondary.withValues(
                                  alpha: 0.1,
                                ),
                              ],
                            ),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.5,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '8',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _LegendItem(
                        label: 'Favorite',
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.redAccent.withValues(alpha: 0.3),
                                Colors.pink.withValues(alpha: 0.08),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Text('❤', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _LegendItem(
                        label: 'Selected',
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '8',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Selected day header ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Date badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSameDay(selectedDay, DateTime.now())
                              ? LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withValues(
                                      alpha: 0.75,
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSameDay(selectedDay, DateTime.now())
                              ? null
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSameDay(selectedDay, DateTime.now())
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _shortMonth(selectedDay.month).toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: isSameDay(selectedDay, DateTime.now())
                                    ? theme.colorScheme.onPrimary.withValues(
                                        alpha: 0.7,
                                      )
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.6,
                                      ),
                              ),
                            ),
                            Text(
                              '${selectedDay.day}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: isSameDay(selectedDay, DateTime.now())
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dayName(selectedDay.weekday).toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.38,
                                ),
                                letterSpacing: 1.2,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              isSameDay(selectedDay, DateTime.now())
                                  ? 'Today'
                                  : _monthName(selectedDay.month),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (dayEntries.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${dayEntries.length} ${dayEntries.length == 1 ? 'entry' : 'entries'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Entries / empty ───────────────────────────────────────
              if (dayEntries.isEmpty)
                SliverToBoxAdapter(child: _EmptyDayView(date: selectedDay))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => FadeTransition(
                        opacity: _entryListFade,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _entryListController,
                                  curve: Interval(
                                    i * 0.12,
                                    1.0,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
                          child: _EntryCard(
                            entry: dayEntries[i],
                            time: _formatEntryTime(dayEntries[i].date),
                            onTap: () => _navigateToEntry(dayEntries[i]),
                          ),
                        ),
                      ),
                      childCount: dayEntries.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DiaryEntryScreen(entry: null),
            ),
          );
          if (result == true && context.mounted) {
            context.read<DiaryBloc>().add(LoadDiaryEntries());
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.edit_outlined, size: 20),
        label: const Text(
          'New Entry',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Beautiful day cell variants
// ─────────────────────────────────────────────────────────────────────────────

/// Selected day — bold gradient circle with optional mood emoji badge.
class _SelectedDayCell extends StatelessWidget {
  final DateTime day;
  final bool hasFav;
  final bool hasEntry;
  final String mood;
  final ThemeData theme;

  const _SelectedDayCell({
    required this.day,
    required this.hasFav,
    required this.hasEntry,
    required this.mood,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = hasFav ? Colors.redAccent : theme.colorScheme.primary;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Outer glow ring
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        // Gradient filled circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: hasFav
                  ? [Colors.redAccent, Colors.pink.shade300]
                  : [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.75),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // Mood emoji badge (top-right)
        if (mood.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(mood, style: const TextStyle(fontSize: 10)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Favorite day — rosy gradient ring + heart badge.
class _FavoriteDayCell extends StatelessWidget {
  final DateTime day;
  final String mood;
  final ThemeData theme;

  const _FavoriteDayCell({
    required this.day,
    required this.mood,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Soft pink radial glow behind the cell
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.redAccent.withValues(alpha: 0.22),
                Colors.pink.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.redAccent,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // Heart badge bottom-right
        Positioned(
          bottom: 1,
          right: 1,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.favorite, size: 8, color: Colors.redAccent),
            ),
          ),
        ),
        // Mood emoji badge top-right
        if (mood.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(mood, style: const TextStyle(fontSize: 9)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Normal entry day — soft tinted circle ring + mood emoji badge.
class _EntryDayCell extends StatelessWidget {
  final DateTime day;
  final String mood;
  final ThemeData theme;

  const _EntryDayCell({
    required this.day,
    required this.mood,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.18),
                theme.colorScheme.secondary.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ),
        ),
        // Mood badge
        if (mood.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Text(mood, style: const TextStyle(fontSize: 9)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Today with no entry — dashed border ring.
class _TodayEmptyCell extends StatelessWidget {
  final DateTime day;
  final ThemeData theme;

  const _TodayEmptyCell({required this.day, required this.theme});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(color: theme.colorScheme.primary),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: Text(
            '${day.day}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed circle painter for today-no-entry cells.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;
    const dashCount = 12;
    const dashAngle = (2 * math.pi) / dashCount;
    const gapFraction = 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

/// Chevron button used inside the calendar header.
class _CalChevron extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _CalChevron({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Other reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColor;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor ?? color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final String label;
  final Color textColor;

  const _IconPill({
    required this.onTap,
    required this.color,
    required this.icon,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final DiaryEntryModel entry;
  final VoidCallback onTap;
  final String time;

  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = entry.isFavorite
        ? Colors.redAccent
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
               border: Border(
                          left: BorderSide(color: accentColor,width: 3.0)
                        ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Mood icon
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                       
                      ),
                      child: Center(
                        child: Text(
                          entry.mood.isEmpty ? '📝' : entry.mood,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                  // Text
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.title.isEmpty
                                      ? 'Untitled'
                                      : entry.title,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (time.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    time,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            entry.preview.isEmpty
                                ? 'No content'
                                : entry.preview,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Trailing
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (entry.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(
                              Icons.favorite,
                              size: 13,
                              color: Colors.redAccent,
                            ),
                          ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.25,
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
      ),
    );
  }
}

class _EmptyDayView extends StatelessWidget {
  final DateTime date;
  const _EmptyDayView({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_note_outlined,
                size: 34,
                color: theme.colorScheme.primary.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nothing written yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to start writing',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Widget child;
  final String label;
  const _LegendItem({required this.child, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
