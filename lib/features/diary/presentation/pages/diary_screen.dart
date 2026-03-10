import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/theme/theme_extenstions.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/pages/entry/diary_entry.dart';
import 'package:routine/features/diary/presentation/pages/history/history_screen.dart';
import 'package:routine/features/settings/presentation/pages/settings_screen.dart';
import 'package:routine/features/diary/presentation/widgets/entry_card_widget.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  int selectedIndex = 0;

  void _onItemTapped(int index) {
    if (selectedIndex == index) return;

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DiaryCalendarScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Icon(
        icon,
        size: 25,
        color:theme.colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        alignment: AlignmentGeometry.bottomCenter,
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
              ),
            ],
          ),

          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 170)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
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
                  }

                  if (state.errorMessage != null) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "Error: ${state.errorMessage}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    );
                  }

                  // Sort all entries by date descending
                  final allEntries = List<DiaryEntryModel>.from(state.entries);
                  allEntries.sort((a, b) {
                    final dateA =
                        DateTime.tryParse(a.date) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final dateB =
                        DateTime.tryParse(b.date) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return dateB.compareTo(dateA);
                  });

                  // Take latest 30 for display
                  final latestEntries = allEntries.take(30).toList();

                  if (latestEntries.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "No entries yet",
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    );
                  }

                  // Build the list of entries
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          DiaryEntryCard(entry: latestEntries[index]),
                      childCount: latestEntries.length,
                    ),
                  );
                },
              ),

              BlocBuilder<DiaryBloc, DiaryState>(
                builder: (context, state) {
                  if (state.entries.length >= 10) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DiaryCalendarScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('View All Entries'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: theme.colorScheme.onPrimary,
                              backgroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 16),
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,             
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // _buildNavItem(icon: Icons.book_outlined, index: 0),
              _buildNavItem(icon: CupertinoIcons.calendar, index: 1),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DiaryEntryScreen(entry: null),
                    ),
                  );

                  if (result == true && context.mounted) {
                    context.read<DiaryBloc>().add(LoadDiaryEntries());
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
                  ),
                ),
              ),
              _buildNavItem(icon: Icons.settings_rounded, index: 2),
              
            ],
          ),
        ),
      )
        ],
      ),

    );
  }
}
