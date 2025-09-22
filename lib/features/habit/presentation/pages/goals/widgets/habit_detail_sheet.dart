import 'package:consist/core/components/progress_indicator.dart';
import 'package:consist/core/utils/common_functions.dart';
import 'package:consist/features/habit/domain/create_habit/entities/habit_model.dart';
import 'package:consist/features/habit/presentation/blocs/habits_bloc/habits_bloc.dart';
import 'package:consist/features/habit/presentation/dialogs/delete_habit_dialog.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/create_habit_screen.dart';
import 'package:consist/features/habit/presentation/pages/habit_analytics/habit_analytics_screen.dart';
import 'package:consist/features/habit/presentation/widgets/app_button.dart';
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
      final bool hasGoal =
          habit.goalValue != null && habit.goalValue!.isNotEmpty;
      return Container(
        width: size.width,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 20,
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
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    spacing: 20,
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
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _buildMetadataChip(
                            Icons.repeat,
                            habit.habitRepeatValue ?? 'Daily',
                          ),
                          _buildMetadataChip(
                            Icons.access_time,
                            habit.habitTime ?? 'Anytime',
                          ),
                          if (hasGoal)
                            _buildMetadataChip(
                              Icons.flag,
                              '${habit.goalCount} ${habit.goalValue}',
                            ),
                        ],
                      ),
                    ],
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
                SizedBox(
                  height: size.height * 0.2,
                  width: size.height * 0.2,
                  child: AnimatedProgressIndicator(
                    progressValue: calculateHabitProgress(habit),
                    beginColor: colorD.withValues(alpha: 0.5),
                    endColor: colorD,
                  ),
                ),
                if (isComplete)
                  Wrap(
                    spacing: 5,
                    children: [
                      Tooltip(
                        message: 'Reset Goal count',
                        child: AppButton(
                          title: 'Reset',
                          onPressed: null,
                          onlyIcon: true,
                          icon: Icons.refresh,
                          color: habitColor.withValues(alpha: 0.5),
                          iconColor: colorD,
                        ),
                      ),
                      Tooltip(
                        message: 'Mark habit as complete',
                        child: AppButton(
                          title: 'Complete now',
                          onPressed: !isComplete
                              ? () {}
                              : () {
                                  context.read<HabitsBloc>().add(
                                    MarkHabitCompleteEvent(habitId: habit.id!),
                                  );
                                  Navigator.pop(context);
                                },
                          icon: Icons.check,
                          color: habitColor.withValues(alpha: 0.5),
                          textColor: colorD,
                          iconColor: colorD,
                        ),
                      ),
                      Tooltip(
                        message: 'Add custom count',
                        child: AppButton(
                          title: 'Add',
                          onPressed: null,
                          onlyIcon: true,
                          icon: Icons.add,
                          color: habitColor.withValues(alpha: 0.5),
                          iconColor: colorD,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
  
}
double calculateHabitProgress(Habit habit) {
    if (habit.goalCount == null ||
        habit.goalCount!.isEmpty ||
        habit.goalValue == null ||
        habit.goalValue!.isEmpty) {
      return 0.0;
    }
    final int goalCount = int.tryParse(habit.goalCount!) ?? 0;
    final int completedCount = int.tryParse(habit.goalCompletedCount ?? '0') ?? 0;

    if (goalCount == 0) return 0.01;
    if (completedCount >= goalCount) return 1.0;
    return (completedCount / goalCount).clamp(0.01, 1.0);
  }

Widget _buildMetadataChip(IconData icon, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: Colors.grey),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );
}
