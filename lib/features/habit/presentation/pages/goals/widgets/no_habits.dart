import 'package:consist/core/constants/habits_items.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/create_habit_screen.dart';
import 'package:consist/features/habit/presentation/pages/goals/widgets/new_routine_sheet.dart';
import 'package:flutter/material.dart';

class HabitLibrary extends StatefulWidget {
  const HabitLibrary({super.key, required this.fromHome});
  final bool fromHome;
  @override
  State<HabitLibrary> createState() => _HabitLibraryState();
}

class _HabitLibraryState extends State<HabitLibrary> {
  String? _selectedHabitId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: CustomScrollView(
        slivers: [
          /// App Bar
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            forceMaterialTransparency: true,
          ),

          /// Header Section
          widget.fromHome
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.explore_outlined,
                          size: 64,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Explore Habit Library",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Browse our collection of popular habits and pick the ones you’d like to track. "
                          "From health to productivity, we’ve got you covered.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          size: 64,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Start Your Journey",
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '''Let’s get started — create your very first habit!\nTake the first step towards positive change today.''',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

          /// Categories + Habits
          SliverList(
            delegate: SliverChildBuilderDelegate((context, categoryIndex) {
              final category = HabitsItems.habitCategories[categoryIndex];

              // Skip "All" category (id:0)
              if (category['id'] == '0') return const SizedBox();

              // Get habits in this category
              final habits = HabitsItems.habitList
                  .where((h) => h['categoryId'] == category['id'])
                  .toList();

              if (habits.isEmpty) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ), // 👈 spacing between categories
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Category Heading
                    Row(
                      children: [
                        Icon(
                          category['icon'],
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category['name'],
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// Habits Grid
                    GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        final selected = _selectedHabitId == habit["id"];

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CreateHabitScreen(
                                  habit: null,
                                  category: habit['categoryId'],
                                  name: habit['name'],
                                  icon: habit['id'],
                                ),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.indigo.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? Colors.indigo
                                    : Colors.grey.shade300,
                                width: selected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: selected
                                      ? Colors.indigo
                                      : Colors.grey.shade200,
                                  child: Icon(
                                    habit["icon"],
                                    color: selected
                                        ? Colors.white
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  habit["name"],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: selected
                                        ? Colors.indigo
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }, childCount: HabitsItems.habitCategories.length),
          ),
        ],
      ),
      floatingActionButton: widget.fromHome ? NewRoutine(isDark: isDark) : null,
    );
  }
}
