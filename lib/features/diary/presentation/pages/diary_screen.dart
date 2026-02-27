import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/theme/theme_extenstions.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/pages/entry/diary_entry.dart';
import 'package:routine/features/diary/presentation/pages/history/history_screen.dart';
import 'package:routine/features/settings/presentation/pages/settings_screen.dart';
import 'package:routine/features/diary/presentation/widgets/entry_card_widget.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
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
                          Theme.of(
                                context,
                              ).extension<BackgroundImageTheme>()?.imagePath ??
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
              ),
            ],
          ),

          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 200)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        "Recent Entries",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
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
                          "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              BlocBuilder<DiaryBloc, DiaryState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (state.errorMessage != null) {
                    return SliverFillRemaining(
                      child: Center(
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
                              "Error: ${state.errorMessage}",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<DiaryBloc>().add(
                                  LoadDiaryEntries(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onPrimary,
                                backgroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text("Try Again"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final now = DateTime.now();
                  final currentMonthEntries = state.entries.where((entry) {
                    final date = DateTime.tryParse(entry.date);
                    return date != null &&
                        date.year == now.year &&
                        date.month == now.month;
                  }).toList();

                  currentMonthEntries.sort((a, b) {
                    final dateA =
                        DateTime.tryParse(a.date) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final dateB =
                        DateTime.tryParse(b.date) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return dateB.compareTo(dateA);
                  });

                  if (currentMonthEntries.isEmpty) {
                    final showHistoryButton = state.entries.length >= 10;

                    return SliverFillRemaining(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.4),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.edit_note,
                                      size: 60,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    "No entries this month",
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Start writing your thoughts...",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (showHistoryButton)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DiaryCalendarScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  backgroundColor: theme.colorScheme.primary,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("View All History"),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = currentMonthEntries[index];
                      return DiaryEntryCard(entry: entry);
                    }, childCount: currentMonthEntries.length),
                  );
                },
              ),

              BlocBuilder<DiaryBloc, DiaryState>(
                builder: (context, state) {
                  if (state.isLoading || state.errorMessage != null) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  final now = DateTime.now();
                  final hasCurrentMonthEntries = state.entries.any((entry) {
                    final date = DateTime.tryParse(entry.date);
                    return date != null &&
                        date.year == now.year &&
                        date.month == now.month;
                  });
                  if (!hasCurrentMonthEntries || state.entries.length < 10) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DiaryCalendarScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onPrimary,
                          backgroundColor: theme.colorScheme.primary,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("View All History"),
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DiaryCalendarScreen(),
                  ),
                ),
                icon: Icon(CupertinoIcons.calendar, size: 26),
                color: theme.colorScheme.primary,
              ),
              Container(
                width: 1,
                height: 30,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              IconButton(
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
                icon: const Icon(Icons.add, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.all(14),
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ),
                icon: const Icon(Icons.menu, size: 26),
                color: theme.colorScheme.primary,
              ),
             
              
            ],
          ),
        ),
      ),
    );
  }
  
}

