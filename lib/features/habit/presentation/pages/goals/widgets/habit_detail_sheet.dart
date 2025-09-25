import 'package:consist/core/components/progress_indicator.dart';
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
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: habit.goalValue != 'Once' ? 0.65 : 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          int count = 0;
          return SafeArea(
            child: BlocConsumer<HabitsBloc, HabitsState>(
              listener: (context, state) {
                if (state is IncrementHabitGoalCountSuccess) {
                  context.read<HabitsBloc>().add(LoadHabitsEvent());
                } else if (state is DecrementHabitGoalCountSuccess) {
                  context.read<HabitsBloc>().add(LoadHabitsEvent());
                } else if (state is UpdateHabitGoalCountSuccess) {
                  context.read<HabitsBloc>().add(LoadHabitsEvent());
                } else if (state is ResetHabitGoalCountSuccess) {
                  context.read<HabitsBloc>().add(LoadHabitsEvent());
                } else if (state is HabitCompleteSuccess) {
                  context.read<HabitsBloc>().add(LoadHabitsEvent());
                } else if (state is IncrementHabitGoalCountError ||
                    state is DecrementHabitGoalCountError ||
                    state is UpdateHabitGoalCountError) {
                  Navigator.pop(context);
                  _showSnack(context, (state as dynamic).message);
                  context.read<HabitsBloc>().add(LoadHabitsEvent());
                }
              },
              builder: (context, state) {
                final habitsState = context.watch<HabitsBloc>().state;

                Habit updatedHabit = habit;
                if (habitsState is HabitsLoaded) {
                  updatedHabit = habitsState.habits.firstWhere(
                    (h) => h.id == habit.id,
                    orElse: () => habit,
                  );
                }

                final bool completed = isHabitCompleted(updatedHabit);
                if (completed) count++;
                if (completed && count == 1) {
                  context.read<HabitsBloc>().add(
                    MarkHabitCompleteEvent(habitId: updatedHabit.id!),
                  );
                }

                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    spacing: 20,
                    children: [
                      _HabitTopBar(habit: updatedHabit),
                      _HabitHeader(
                        habit: updatedHabit,
                        size: size,
                        habitColor: habitColor,
                        colorD: colorD,
                        isDark: isDark,
                        habitIcon: habitIcon,
                      ),
                      if (updatedHabit.note != null &&
                          updatedHabit.note!.isNotEmpty)
                        _HabitNotesCard(note: updatedHabit.note!),
                      if (habit.goalValue != 'Once')
                        _ProgressCircle(
                          habit: updatedHabit,
                          size: size,
                          colorD: colorD,
                        ),
                      Text(
                        (updatedHabit.goalValue != null &&
                                updatedHabit.goalValue!.isNotEmpty)
                            ? completed
                                  ? 'Goal Completed for today'
                                  : 'Keep going!'
                            : 'Set a goal to track progress',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: colorD),
                      ),
                      if (!completed)
                        _HabitActions(
                          habit: updatedHabit,
                          habitColor: habitColor,
                          colorD: colorD,
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}

/// === Top bar with delete, analytics, edit ===
class _HabitTopBar extends StatelessWidget {
  const _HabitTopBar({required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () async {
              final confirm = await showDeleteHabitDialog(context);
              if (confirm == true && context.mounted) {
                context.read<HabitsBloc>().add(DeleteHabitEvent(habit.id!));
                Navigator.pop(context);
              }
            },
            icon: const Icon(CupertinoIcons.delete),
          ),
          IconButton(
            onPressed: () => context.read<HabitsBloc>().add(
              ResetHabitGoalCountEvent(habitId: habit.id!),
            ),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HabitAnalyticsScreen(habitId: habit.id!),
              ),
            ),
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    CreateHabitScreen(habit: habit, category: habit.category!),
              ),
            ),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }
}

/// === Header with icon, name, repeat, time, goal ===
class _HabitHeader extends StatelessWidget {
  const _HabitHeader({
    required this.habit,
    required this.size,
    required this.habitColor,
    required this.colorD,
    required this.isDark,
    this.habitIcon,
  });

  final Habit habit;
  final Size size;
  final Color habitColor;
  final Color colorD;
  final bool isDark;
  final IconData? habitIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        spacing: 20,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark
                  ? Colors.white10
                  : habitColor.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.all(5),
            child: Icon(habitIcon, color: colorD, size: size.width * 0.1),
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
              if (habit.goalValue != null && habit.goalValue!.isNotEmpty)
                _buildMetadataChip(
                  Icons.flag,
                  '${habit.goalCount} ${habit.goalValue}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// === Notes Card ===
class _HabitNotesCard extends StatelessWidget {
  const _HabitNotesCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Note', style: Theme.of(context).textTheme.headlineSmall),
              Text(note, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// === Progress Circle with + / - ===
class _ProgressCircle extends StatelessWidget {
  const _ProgressCircle({
    required this.habit,
    required this.size,
    required this.colorD,
  });

  final Habit habit;
  final Size size;
  final Color colorD;

  @override
  Widget build(BuildContext context) {
    final bool completed = isHabitCompleted(habit);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!completed)
          CircleAvatar(
            backgroundColor: Colors.black12,
            child: IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => context.read<HabitsBloc>().add(
                DecrementHabitGoalCountEvent(habitId: habit.id!),
              ),
            ),
          ),
        Stack(
          children: [
            SizedBox(
              height: size.height * 0.2,
              width: size.height * 0.2,
              child: AnimatedProgressIndicator(
                progressValue: calculateHabitProgress(habit),
                beginColor: colorD.withValues(alpha: 0.5),
                endColor: colorD,
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  (habit.goalValue != null && habit.goalValue!.isNotEmpty)
                      ? '${habit.goalCompletedCount ?? '0'}/${habit.goalCount} ${habit.goalValue}'
                      : 'No Goal',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: colorD),
                ),
              ),
            ),
          ],
        ),
        if (!completed)
          CircleAvatar(
            backgroundColor: Colors.black12,
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.read<HabitsBloc>().add(
                IncrementHabitGoalCountEvent(habitId: habit.id!),
              ),
            ),
          ),
      ],
    );
  }
}

/// === Action buttons: reset, complete, custom add ===
class _HabitActions extends StatelessWidget {
  const _HabitActions({
    required this.habit,
    required this.habitColor,
    required this.colorD,
  });

  final Habit habit;
  final Color habitColor;
  final Color colorD;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context: context,
          icon: Icons.refresh,
          label: 'Reset',
          colorD: colorD,
          onPressed: () => context.read<HabitsBloc>().add(
            ResetHabitGoalCountEvent(habitId: habit.id!),
          ),
          tooltip: 'Reset goal count',
        ),
        _buildActionButton(
          context: context,
          icon: Icons.check,
          label: 'Complete',
          colorD: colorD,
          onPressed: () => context.read<HabitsBloc>().add(
            MarkHabitCompleteEvent(habitId: habit.id!),
          ),
          tooltip: 'Mark as complete',
          isPrimary: true,
        ),
       if (habit.goalValue != 'Once')  _buildActionButton(
          context: context,
          icon: Icons.add,
          label: 'Custom',
          colorD: colorD,
          onPressed: () => showDialog(
            context: context,
            builder: (context) {
              final TextEditingController controller = TextEditingController();
              return AlertDialog(
                title: const Text('Add Custom Count'),
                content: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter count to add',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final int? value = int.tryParse(controller.text);
                      if (value != null && value > 0) {
                        context.read<HabitsBloc>().add(
                          UpdateHabitGoalCountEvent(
                            habitId: habit.id!,
                            count: value,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        _showSnack(context, 'Please enter a valid number');
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          ),
          tooltip: 'Add custom count',
        ),
      ],
    );
  }
}

/// === Helpers ===
void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

bool isHabitCompleted(Habit habit) {
  if (habit.goalValue != null && habit.goalValue == 'Once') {
    return CommonFunctions.isNewDayForHabit(habit.isCompleteToday) == false;
  } else if (habit.goalValue == null ||
      habit.goalValue!.isEmpty ||
      habit.goalCount == null ||
      habit.goalCount!.isEmpty) {
    return false;
  }

  final int goalCount = int.tryParse(habit.goalCount!) ?? 0;
  final int completedCount = int.tryParse(habit.goalCompletedCount ?? '0') ?? 0;

  return goalCount > 0 && completedCount >= goalCount;
}

Widget _buildMetadataChip(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionButton({
  required BuildContext context,
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
  required String tooltip,
  required Color colorD,
  bool isPrimary = false,
}) {
  return Tooltip(
    message: tooltip,
    child: Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isPrimary ? colorD : colorD.withValues(alpha: 0.1),
          child: IconButton(
            icon: Icon(
              icon,
              color: isPrimary ? Colors.white : colorD,
              size: 18,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorD,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class CustomCountInput extends StatefulWidget {
  final Color colorD;
  final int habitId;

  const CustomCountInput({
    super.key,
    required this.colorD,
    required this.habitId,
  });

  @override
  State<CustomCountInput> createState() => _CustomCountInputState();
}

class _CustomCountInputState extends State<CustomCountInput> {
  bool _editing = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final int? value = int.tryParse(_controller.text);
    if (value != null && value > 0) {
      context.read<HabitsBloc>().add(
        UpdateHabitGoalCountEvent(
          habitId: widget.habitId.toString(),
          count: value,
        ),
      );
      // hide the input after submit
      setState(() {
        _editing = false;
      });
    } else {
      _showSnack(context, 'Please enter a valid number');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return SizedBox(
        width: 80, // or your desired width
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Count',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onSubmitted: (_) => _submit(),
        ),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.add),
        color: widget.colorD,
        tooltip: 'Custom',
        onPressed: () {
          setState(() {
            _editing = true;
          });
          // after entering editing = true, we want to request focus on the text field
          // Wait a bit for rebuild then requestFocus
          Future.delayed(Duration(milliseconds: 50), () {
            if (mounted) {
              _focusNode.requestFocus();
            }
          });
        },
      );
    }
  }
}
