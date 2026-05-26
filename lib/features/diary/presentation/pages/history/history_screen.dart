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

class DiaryCalendarScreen extends StatefulWidget {
  const DiaryCalendarScreen({super.key});

  @override
  State<DiaryCalendarScreen> createState() => _DiaryCalendarScreenState();
}

class _DiaryCalendarScreenState extends State<DiaryCalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  List<DiaryEntryModel> _getEntriesForDay(
    DateTime day,
    List<DiaryEntryModel> allEntries,
  ) {
    final normalizedDay = _normalizeDate(day);
    return allEntries.where((e) {
      final date = DateTime.tryParse(e.date) ?? DateTime.now();
      return _normalizeDate(date) == normalizedDay;
    }).toList();
  }

  Set<DateTime> _calculateMarkedDates(List<DiaryEntryModel> entries) {
    return entries.map((e) {
      final date = DateTime.tryParse(e.date) ?? DateTime.now();
      return _normalizeDate(date);
    }).toSet();
  }

  bool _dayHasFavorite(DateTime day, List<DiaryEntryModel> entries) {
    return entries.any((e) {
      final d = DateTime.tryParse(e.date) ?? DateTime.now();
      return _normalizeDate(d) == _normalizeDate(day) && e.isFavorite;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
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
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
        pageBuilder: (_, animation, __) => const DiaryFavoritesScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
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

          return Stack(
            children: [
              // ── Hero background ────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 260,
                child: Image.asset(bgImagePath, fit: BoxFit.cover),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 260,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Scrollable content ─────────────────────────────────
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Collapsible hero header ──────────────────────
                  SliverAppBar(
                    expandedHeight: 200,
                    collapsedHeight: 60,
                    pinned: true,
                    stretch: true,
                    backgroundColor: theme.colorScheme.primary,
                    surfaceTintColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        // 0.0 = fully expanded, 1.0 = fully collapsed
                        final expandRatio =
                            ((constraints.maxHeight - 60) / (200 - 60)).clamp(
                              0.0,
                              1.0,
                            );

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background image fades out as collapsed
                            Opacity(
                              opacity: expandRatio,
                              child: Image.asset(
                                bgImagePath,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Opacity(
                              opacity: expandRatio,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.2),
                                      Colors.black.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Title content — fades in when expanded
                            Positioned(
                              bottom: 16,
                              left: 20,
                              right: 20,
                              child: Opacity(
                                opacity: expandRatio,
                                child: FadeTransition(
                                  opacity: _headerFadeAnim,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Memory',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                              height: 1,
                                            ),
                                      ),
                                      Text(
                                        'Timeline',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                              fontWeight: FontWeight.w300,
                                              letterSpacing: -0.5,
                                              height: 1.1,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${entries.length} entries · $favCount favorites',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.65,
                                              ),
                                              letterSpacing: 0.3,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // ── Calendar card ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _buildCalendar(
                            context,
                            theme,
                            entries,
                            markedDates,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Legend row ───────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        children: [
                          _LegendDot(
                            color: theme.colorScheme.secondary,
                            label: 'Has entry',
                          ),
                          const SizedBox(width: 16),
                          _LegendDot(
                            color: Colors.redAccent,
                            label: 'Favorites',
                            icon: Icons.favorite,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Day entries section ──────────────────────────
                  if (_selectedDay != null) ...[
                    SliverToBoxAdapter(
                      child: _DayHeader(
                        date: _selectedDay!,
                        label: _formatDate(_selectedDay!),
                        entryCount: dayEntries.length,
                      ),
                    ),
                    if (dayEntries.isEmpty)
                      SliverToBoxAdapter(
                        child: _EmptyDayView(date: _selectedDay!),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _EntryCard(
                              entry: dayEntries[index],
                              onTap: () => _navigateToEntry(dayEntries[index]),
                            ),
                            childCount: dayEntries.length,
                          ),
                        ),
                      ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),

              // ── Floating nav bar (back + favorites) ──────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        _FloatingPill(
                          onTap: () => Navigator.pop(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.back,
                                size: 18,
                                color: theme.colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Back',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Favorites button — always visible ──────
                        _FloatingPill(
                          onTap: _goToFavorites,
                          color: Colors.redAccent,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Favorites',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          'New Entry',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Calendar widget ──────────────────────────────────────────────────────

  Widget _buildCalendar(
    BuildContext context,
    ThemeData theme,
    List<DiaryEntryModel> entries,
    Set<DateTime> markedDates,
  ) {
    return TableCalendar(
      availableGestures: AvailableGestures.horizontalSwipe,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        isTodayHighlighted: true,
        selectedDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary,
        ),
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        todayTextStyle: theme.textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
        markersMaxCount: 1,
        markerSize: 0,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ),
        leftChevronIcon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chevron_left,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        rightChevronIcon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: theme.textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        weekendStyle: theme.textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary.withValues(alpha: 0.65),
        ),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return _buildDayCell(
            context: context,
            day: day,
            entries: entries,
            markedDates: markedDates,
            isToday: isSameDay(day, DateTime.now()),
            isSelected: isSameDay(_selectedDay, day),
          );
        },

        todayBuilder: (context, day, focusedDay) {
          return _buildDayCell(
            context: context,
            day: day,
            entries: entries,
            markedDates: markedDates,
            isToday: true,
            isSelected: isSameDay(_selectedDay, day),
          );
        },

        selectedBuilder: (context, day, focusedDay) {
          return _buildDayCell(
            context: context,
            day: day,
            entries: entries,
            markedDates: markedDates,
            isToday: isSameDay(day, DateTime.now()),
            isSelected: true,
          );
        },

        markerBuilder: (context, day, events) {
          final normalizedDay = _normalizeDate(day);
          final hasFav = _dayHasFavorite(day, entries);
          final isMarked = markedDates.contains(normalizedDay);

          if (hasFav) {
            return Positioned(
              bottom: 3,
              child: Icon(
                Icons.favorite,
                size: 7,
                color: Colors.redAccent.withValues(alpha: 0.9),
              ),
            );
          }
          if (isMarked) {
            return Positioned(
              bottom: 3,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDayCell({
    required BuildContext context,
    required DateTime day,
    required List<DiaryEntryModel> entries,
    required Set<DateTime> markedDates,
    required bool isToday,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    final normalizedDay = _normalizeDate(day);

    final hasEntry = markedDates.contains(normalizedDay);
    final hasFavorite = _dayHasFavorite(day, entries);

    final textColor = isSelected
        ? theme.colorScheme.onPrimary
        : hasFavorite
        ? Colors.redAccent
        : theme.colorScheme.onSurface;

    // Selected state overrides everything
    if (isSelected) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      );
    }

    // Favorite = heart shape
    if (hasFavorite) {
  return Container(
    margin: const EdgeInsets.all(2),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.favorite,
          size: 42,
          color: Colors.redAccent.withValues(alpha: 0.22),
        ),

        Transform.translate(
          offset: const Offset(0, -1),
          child: Text(
            '${day.day}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    ),
  );
}

    // Normal entry = circle
    if (hasEntry) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.secondary.withValues(alpha: 0.15),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.35),
          ),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      );
    }

    // Today without entry
    if (isToday) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      );
    }

    // Default day
    return Center(
      child: Text(
        '${day.day}',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Reusable widgets ─────────────────────────────────────────────────────────

/// Floating pill button used in the top overlay row.
class _FloatingPill extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color? color;

  const _FloatingPill({required this.onTap, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Sticky action bar below the collapsing SliverAppBar.
class ActionBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const ActionBarDelegate({required this.child});

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(ActionBarDelegate old) => old.child != child;
}

/// Section header for the selected day's entries.
class _DayHeader extends StatelessWidget {
  final DateTime date;
  final String label;
  final int entryCount;

  const _DayHeader({
    required this.date,
    required this.label,
    required this.entryCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (entryCount > 0)
                  Text(
                    '$entryCount ${entryCount == 1 ? 'entry' : 'entries'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (entryCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${date.day}/${date.month}/${date.year}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single diary entry card in the day list.
class _EntryCard extends StatelessWidget {
  final DiaryEntryModel entry;
  final VoidCallback onTap;

  const _EntryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: entry.isFavorite
                  ? Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                      width: 1.5,
                    )
                  : Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Mood
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: entry.isFavorite
                          ? Colors.redAccent.withValues(alpha: 0.08)
                          : theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        entry.mood.isEmpty ? '😊' : entry.mood,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title.isEmpty ? 'Untitled' : entry.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entry.preview.isEmpty ? 'No content' : entry.preview,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Trailing
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (entry.isFavorite)
                        const Icon(
                          Icons.favorite,
                          size: 14,
                          color: Colors.redAccent,
                        ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                        size: 20,
                      ),
                    ],
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

/// Shown when the selected day has no entries.
class _EmptyDayView extends StatelessWidget {
  final DateTime date;
  const _EmptyDayView({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 32,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No entries on this day',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap + to write something',
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

/// Legend dot for calendar key.
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final IconData? icon;

  const _LegendDot({required this.color, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 10, color: color)
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Full-screen error view.
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
