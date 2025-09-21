import 'package:consist/core/utils/common_functions.dart';
import 'package:consist/features/habit/domain/create_habit/entities/habit_model.dart';
import 'package:consist/features/habit/presentation/blocs/habits_bloc/habits_bloc.dart';
import 'package:consist/features/habit/presentation/dialogs/delete_habit_dialog.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/create_habit_screen.dart';
import 'package:consist/features/habit/presentation/pages/habit_analytics/habit_analytics_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<dynamic> habitDetailSheet({
  required BuildContext context,
  required Size size,
  required Color habitColor,
  required Color colorD,
  IconData? habitIcon,
  required Habit habit,
  required bool isDark,
}) {
  return showModalBottomSheet(
    context: context,

    builder: (context) {
      bool isComplete = CommonFunctions.isNewDayForHabit(habit.isCompleteToday);
      return Container(
        width: size.width,
        decoration: BoxDecoration(
          color: habitColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.black,

                  actions: [
                    IconButton(
                      onPressed: () async {
                        final confirm = await showDeleteHabitDialog(context);

                        if (confirm != null && confirm && context.mounted) {
                          context.read<HabitsBloc>().add(
                            DeleteHabitEvent(habit.id!),
                          );
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(CupertinoIcons.delete),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              HabitAnalyticsScreen(habitId: habit.id!),
                        ),
                      ),

                      icon: Icon(Icons.bar_chart),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CreateHabitScreen(
                            habit: habit,
                            category: habit.category!,
                          ),
                        ),
                      ),
                      icon: Icon(Icons.edit),
                    ),
                  ],
                ),
              ),
              Card(
                margin: const EdgeInsets.all(10),
                child: SizedBox(
                  width: size.width,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      spacing: 10,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                            color: isDark
                                ? Colors.white10
                                : habitColor.withValues(alpha: 0.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(
                              habitIcon,
                              color: colorD,
                              size: size.width * 0.1,
                            ),
                          ),
                        ),
                        Text(
                          habit.habitName ?? 'Habit Name',
                          style: Theme.of(context).textTheme.headlineMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 5,
                          children: [
                            Icon(Icons.repeat, color: Colors.grey),
                            Text(
                              habit.habitRepeatValue ?? 'Daily',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              "●",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),

                            Text(
                              habit.habitTime ?? 'Anytime',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (habit.note != null && habit.note != '')
                Card(
                  margin: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: size.width,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            habit.note ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isComplete)
                GestureDetector(
                  onTap: !isComplete
                      ? () {}
                      : () {
                          context.read<HabitsBloc>().add(
                            MarkHabitCompleteEvent(habitId: habit.id!),
                          );
                          Navigator.pop(context);
                        },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        spacing: 5,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.green),
                          Text(
                            'Complete now',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
