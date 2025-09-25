import 'package:consist/core/utils/common_functions.dart';
import 'package:consist/features/habit/domain/create_habit/entities/habit_model.dart';
import 'package:consist/features/habit/presentation/pages/goals/widgets/habit_detail_sheet.dart';
import 'package:flutter/material.dart';

class GoalsList extends StatelessWidget {
  const GoalsList({
    super.key,
    required this.habits,
    required this.isDark,
    required this.size,
  });

  final List<Habit> habits;
  final bool isDark;
  final Size size;

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Center(child: Text('No habits found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(5),
      itemCount: habits.length,
      itemBuilder: (BuildContext context, int index) {
        final Habit habit = habits[index];
        return _HabitListItem(
          habit: habit,
          isDark: isDark,
          size: size,
        );
      },
    );
  }
}

class _HabitListItem extends StatelessWidget {
  const _HabitListItem({
    required this.habit,
    required this.isDark,
    required this.size,
  });

  final Habit habit;
  final bool isDark;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final Color habitColor = CommonFunctions.getColorById(
      habit.habitColorId ?? '',
    ) ?? Theme.of(context).colorScheme.secondary;
    
    final Color colorD = CommonFunctions.darken(habitColor);
    final IconData? habitIcon = CommonFunctions.getIconById(
      habit.habitIconId ?? '',
    );
    
    final bool isComplete = CommonFunctions.isNewDayForHabit(
      habit.isCompleteToday,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: _buildLeading(habitColor, habitIcon, colorD),
        title: _buildTitle(context, habit),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        trailing: _buildTrailing(context, habit, isComplete, colorD, habitColor),
        onTap: () => _showHabitDetailSheet(
          context,
          habit,
          habitColor,
          colorD,
          habitIcon,
        ),
      ),
    );
  }

  Widget _buildLeading(Color habitColor, IconData? habitIcon, Color colorD) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: isDark ? Colors.white10 : habitColor.withAlpha(128),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(habitIcon, color: colorD),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, Habit habit) {
    return Text(habit.habitName ?? 'Unnamed Habit');
  }

  Widget _buildTrailing(
    BuildContext context,
    Habit habit,
    bool isComplete,
    Color colorD,
    Color habitColor,
  ) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: !isComplete
          ? colorD
          : isDark
              ? Colors.white10
              : habitColor.withAlpha(128),
      child: const Icon(Icons.check, color: Colors.white),
    );
  }

  void _showHabitDetailSheet(
    BuildContext context,
    Habit habit,
    Color habitColor,
    Color colorD,
    IconData? habitIcon,
  ) {
    habitDetailSheet(
      context: context,
      size: size,
      habitColor: habitColor,
      colorD: colorD,
      habit: habit,
      isDark: isDark,
      habitIcon: habitIcon,
    );
  }
}