import 'package:consist/core/utils/common_functions.dart';
import 'package:consist/features/habit/domain/create_habit/entities/habit_model.dart';
import 'package:consist/features/habit/presentation/blocs/habits_bloc/habits_bloc.dart';
import 'package:consist/features/habit/presentation/pages/goals/widgets/habit_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return habits.isEmpty
        ? const Center(child: Text("No habits found"))
        : ListView.builder(
            padding: const EdgeInsets.all(5),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              Color? habitColor =
                  CommonFunctions.getColorById(habit.habitColorId ?? "") ??
                  Theme.of(context).colorScheme.secondary;
              Color colorD = CommonFunctions.darken(habitColor);
    
              IconData? habitIcon = CommonFunctions.getIconById(
                habit.habitIconId ?? "",
              );
              bool isComplete = CommonFunctions.isNewDayForHabit(
                habit.isCompleteToday,
              );
    
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: _leading(habitColor, habitIcon, colorD),
                  title: _title(
                    context,
                    habitColor,
                    colorD,
                    habit,
                    habitIcon,
                  ),
                  titleTextStyle: Theme.of(context).textTheme.headlineSmall!
                      .copyWith(fontWeight: FontWeight.w800),
                  trailing: _trailing(
                    context,
                    habit,
                    isComplete,
                    colorD,
                    habitColor,
                  ),
                ),
              );
            },
          );
  }

  GestureDetector _trailing(
    BuildContext context,
    Habit habit,
    bool isComplete,
    Color colorD,
    Color habitColor,
  ) {
    return GestureDetector(
      onTap: !isComplete
          ? () {}
          : () => context.read<HabitsBloc>().add(
              MarkHabitCompleteEvent(habitId: habit.id!),
            ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: !isComplete
            ? colorD
            : isDark
            ? Colors.white10
            : habitColor.withAlpha(128),
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  GestureDetector _title(
    BuildContext context,
    Color habitColor,
    Color colorD,
    Habit habit,
    IconData? habitIcon,
  ) {
    return GestureDetector(
      onTap: () => habitDetailSheet(
        context: context,
        size: size,
        habitColor: habitColor,
        colorD: colorD,
        habit: habit,
        isDark: isDark,
        habitIcon: habitIcon,
      ),
      child: Text(habit.habitName ?? "Unnamed Habit"),
    );
  }

  Container _leading(Color habitColor, IconData? habitIcon, Color colorD) {
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
}
