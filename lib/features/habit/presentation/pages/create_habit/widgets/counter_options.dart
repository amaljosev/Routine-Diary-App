import 'package:consist/core/constants/habits_items.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/bloc/create_bloc.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/habit_create_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoalValue extends StatelessWidget {
  const GoalValue({
    super.key,
    required this.isDark,
    required this.goalValue,
    required this.goalCount,
    required this.habitId,
  });

  final String? goalValue;
  final String? goalCount;
  final bool isDark;
  final String? habitId;

  @override
  Widget build(BuildContext context) {
    return HabitCreationTile(
      icon: Icons.timer_outlined,
      title: 'Goal Value',
      trailing: '${goalCount ?? '1'} ${goalValue ?? 'once'} per day',
      onTap: () => showModalBottomSheet(
        showDragHandle: true,
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return BlocProvider.value(
            value: context.read<CreateBloc>(),
            child: GoalValuePicker(
              habitId: habitId,
              goalCount: goalCount,
              goalValue: goalValue,
            ),
          );
        },
      ),
    );
  }
}

class GoalValuePicker extends StatefulWidget {
  final String? goalCount;
  final String? goalValue;
  final String? habitId;

  const GoalValuePicker({
    super.key,
    this.goalCount,
    this.goalValue,
    required this.habitId,
  });

  @override
  State<GoalValuePicker> createState() => _GoalValuePickerState();
}

class _GoalValuePickerState extends State<GoalValuePicker> {
  int selectedCount = 1;
  String selectedUnit = "";
  List<String> availableUnits = HabitsItems.goalUnits; // default

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _parseCurrentValues();
  }

  void _loadUnits() {
    if (widget.habitId != null) {
      final habit = HabitsItems.habitList.firstWhere(
        (h) => h["id"] == widget.habitId,
        orElse: () => {},
      );

      if (habit.isNotEmpty && habit["countOptions"] != null) {
        availableUnits = List<String>.from(habit["countOptions"]);
      }
    }

    // Ensure a valid default unit
    selectedUnit = availableUnits.first;
  }

  void _parseCurrentValues() {
    // Parse goal count
    if (widget.goalCount != null && widget.goalCount!.isNotEmpty) {
      selectedCount = int.tryParse(widget.goalCount!) ?? 1;
    }

    // Parse goal unit/value
    if (widget.goalValue != null && widget.goalValue!.isNotEmpty) {
      if (availableUnits.contains(widget.goalValue)) {
        selectedUnit = widget.goalValue!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set Goal Value',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Dual Picker Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Count Picker
                Expanded(
                  child: Column(
                    children: [
                      Text('Count', style: Theme.of(context).textTheme.labelLarge),
                      SizedBox(
                        height: 150,
                        child: CupertinoPicker(
                          itemExtent: 40,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedCount - 1,
                          ),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedCount = index + 1;
                            });
                          },
                          children: List.generate(100, (index) {
                            final count = index + 1;
                            return Center(
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: count == selectedCount
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                // Unit Picker
                Expanded(
                  child: Column(
                    children: [
                      Text('Unit', style: Theme.of(context).textTheme.labelLarge),
                      SizedBox(
                        height: 150,
                        child: CupertinoPicker(
                          itemExtent: 40,
                          scrollController: FixedExtentScrollController(
                            initialItem: availableUnits.indexOf(selectedUnit),
                          ),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedUnit = availableUnits[index];
                            });
                          },
                          children: availableUnits.map((unit) {
                            return Center(
                              child: Text(
                                unit,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: unit == selectedUnit
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Selected Value Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$selectedCount $selectedUnit per day',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      context.read<CreateBloc>().add(
                            UpdateHabitGoalValueEvent(selectedUnit),
                          );
                      context.read<CreateBloc>().add(
                            UpdateHabitGoalCountEvent(selectedCount.toString()),
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
