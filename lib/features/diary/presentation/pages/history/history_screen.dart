import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/theme/theme_extenstions.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/pages/entry/diary_entry.dart';
import 'package:routine/features/diary/presentation/pages/preview/diary_preview.dart';
import 'package:table_calendar/table_calendar.dart';

class DiaryCalendarScreen extends StatefulWidget {
  const DiaryCalendarScreen({super.key});

  @override
  State<DiaryCalendarScreen> createState() => _DiaryCalendarScreenState();
}

class _DiaryCalendarScreenState extends State<DiaryCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

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

  void _onDaySelected(
    DateTime selectedDay,
    DateTime focusedDay,
    List<DiaryEntryModel> entries,
  ) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _navigateToEntry(DiaryEntryModel entry) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DiaryPreviewScreen(entryId: entry.id)),
    );
    if (result == true && mounted) {
      context.read<DiaryBloc>().add(LoadDiaryEntries());
    }
  }

  Set<DateTime> _calculateMarkedDates(List<DiaryEntryModel> entries) {
    return entries.map((e) {
      final date = DateTime.tryParse(e.date) ?? DateTime.now();
      return _normalizeDate(date);
    }).toSet();
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
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
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<DiaryBloc, DiaryState>(
        builder: (context, state) {
          // Handle loading, error, and empty states with full‑screen slivers
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.errorMessage}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<DiaryBloc>().add(LoadDiaryEntries()),
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

          final entries = state.entries;
          final markedDates = _calculateMarkedDates(entries);
          final dayEntries = _selectedDay != null
              ? _getEntriesForDay(_selectedDay!, entries)
              : <DiaryEntryModel>[];

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    expandedHeight: 200,
                    stretch: true,
                    backgroundColor: theme.colorScheme.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.blurBackground],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'headerTag',
                            child: Image.asset(
                              Theme.of(context)
                                      .extension<BackgroundImageTheme>()
                                      ?.imagePath ??
                                  'assets/img/themes/theme_1.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                    floating: false,
                    pinned: false,
                    snap: false,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    title: Text('Memory Timeline'),
                  ),
                ],
              ),

              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    automaticallyImplyLeading: false,

                    title: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          CupertinoIcons.back,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    centerTitle: false,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: TableCalendar(
                            availableGestures:
                                AvailableGestures.horizontalSwipe,
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) =>
                                _onDaySelected(
                                  selectedDay,
                                  focusedDay,
                                  entries,
                                ),
                            onPageChanged: (focusedDay) =>
                                setState(() => _focusedDay = focusedDay),

                            calendarStyle: CalendarStyle(
                              isTodayHighlighted: true,
                              selectedDecoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).primaryColor,
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              todayDecoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.15,
                                ),

                                shape: BoxShape.circle,
                              ),
                              todayTextStyle: theme.textTheme.bodySmall!
                                  .copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                              markersMaxCount: 1,
                              markerSize: 0,
                            ),

                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: theme.textTheme.titleLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: theme.textTheme.bodySmall!.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              weekendStyle: theme.textTheme.bodySmall!.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            calendarBuilders: CalendarBuilders(
                              defaultBuilder: (context, day, focusedDay) {
                                final isMarked = markedDates.contains(day);
                                final isSelected = isSameDay(_selectedDay, day);
                                final isToday = isSameDay(day, DateTime.now());
                                return Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isMarked
                                        ? theme.colorScheme.secondary
                                              .withValues(alpha: 0.15)
                                        : null,
                                    border: isSelected
                                        ? Border.all(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                );
                              },
                              markerBuilder: (context, day, events) {
                                if (markedDates.contains(day)) {
                                  return Positioned(
                                    bottom: 2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.secondary
                                                .withValues(alpha: 0.5),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (dayEntries.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Row(
                          children: [
                            Text(
                              'Entries for ${_formatDate(_selectedDay!)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entry = dayEntries[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  entry.mood.isEmpty ? '😊' : entry.mood,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              title: Text(
                                entry.title.isEmpty ? 'Untitled' : entry.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                entry.preview.isEmpty
                                    ? 'No content'
                                    : entry.preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              onTap: () => _navigateToEntry(entry),
                            ),
                          ),
                        );
                      }, childCount: dayEntries.length),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                  if (_selectedDay != null && dayEntries.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No entries for this day',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
