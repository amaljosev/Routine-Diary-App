import 'dart:io';
import 'package:consist/core/utils/common_functions.dart';
import 'package:consist/core/utils/converters.dart';
import 'package:consist/core/widgets/loading_widget.dart';
import 'package:consist/features/habit/domain/create_habit/entities/habit_model.dart';
import 'package:consist/features/habit/presentation/blocs/habits_bloc/habits_bloc.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/bloc/create_bloc.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/add_note_widget.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/bg_color_picker.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/counter_options.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/duration_widget.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/habit_category_widget.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/habit_icon.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/habit_remainder.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/habit_repeat.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/habit_start_at_widget.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/habit_time_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateHabitScreen extends StatelessWidget {
  const CreateHabitScreen({
    super.key,
    required this.category,
    this.name,
    this.habit,
    this.icon,
  });
  final String category;
  final String? name;
  final Habit? habit;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateBloc(),
      child: CreateScreen(
        category: category,
        name: name,
        habit: habit,
        icon: icon,
      ),
    );
  }
}

class CreateScreen extends StatefulWidget {
  const CreateScreen({
    super.key,
    required this.category,
    required this.habit,
    this.name,
    this.icon,
  });
  final String category;
  final String? name;
  final Habit? habit;
  final String? icon;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final noteController = TextEditingController();
  final nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    context.read<CreateBloc>().add(
      InitializeCreateEvent(
        category: widget.category,
        habit: widget.habit,
        iconId: widget.icon,
      ),
    );
    if (widget.name != null) {
      nameController.text = widget.name ?? '';
    }

    if (widget.habit != null) {
      nameController.text = widget.habit!.habitName ?? '';
      noteController.text = widget.habit!.note ?? '';
    }
    super.initState();
  }

  @override
  void dispose() {
    noteController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<CreateBloc, CreateState>(
      listener: (context, state) {
        if (state is CreateSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.of(context).pop();
        } else if (state is CreateError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is CreateValidationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${state.field}: ${state.message}')),
          );
        }
      },
      builder: (context, state) {
        if (state is CreateInitial) {
          final habit = state.habit;
          return Scaffold(
            backgroundColor: CommonFunctions.getColorById(habit.habitColorId!),
            appBar: AppBar(
              backgroundColor: CommonFunctions.getColorById(
                habit.habitColorId!,
              ),
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(
                  Platform.isAndroid ? Icons.arrow_back : CupertinoIcons.back,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                TextButton(
                  onPressed: () => _formKey.currentState!.validate()
                      ? _createHabit(context, habit, widget.habit != null)
                      : null,
                  child: Text(
                    widget.habit != null ? 'Update' : 'Create',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: SafeArea(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 20,
                      children: [
                        HabitIcon(isDark: isDark, icon: habit.habitIconId),
                        TextFormField(
                          controller: nameController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration.collapsed(
                            hintText: 'New Habit',
                            hintStyle: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black38,
                                ),
                          ),
                          style: Theme.of(context).textTheme.headlineMedium!
                              .copyWith(color: Colors.black),
                          maxLength: 40,
                          maxLines: null,
                          cursorWidth: 4,
                          onChanged: (val) {
                            context.read<CreateBloc>().add(
                              UpdateHabitNameEvent(val),
                            );
                          },

                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a habit name';
                            }
                            return null;
                          },
                        ),
                        HabitColor(
                          bgClr: CommonFunctions.getColorById(
                            habit.habitColorId!,
                          ),
                        ),

                        if (habit.category != '3')
                          Card(
                            color: isDark ? Colors.black26 : null,
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  HabitCategoryWidget(
                                    habitCategory: habit.category,
                                    isDark: isDark,
                                    isUpdate: widget.habit != null,
                                  ),
                                  Divider(
                                    height: 0,
                                    color: isDark ? null : Colors.black12,
                                  ),
                                  GoalValue(
                                    isDark: isDark,
                                    goalValue: habit.goalValue,
                                    habitId: widget.icon,
                                    goalCount: habit.goalCount,
                                  ),
                                  Divider(
                                    height: 0,
                                    color: isDark ? null : Colors.black12,
                                  ),
                                  if (widget.habit == null)
                                    HabitTimeWidget(habitTime: habit.habitTime),
                                  Divider(
                                    height: 0,
                                    color: isDark ? null : Colors.black12,
                                  ),

                                  if (habit.category != '3')
                                    HabitRepeatWidget(
                                      habitRepeat: habit.habitRepeatValue,

                                      bgColor: AppConverters.stringToColor(
                                        habit.habitColorId,
                                      ),
                                    ),
                                  Divider(
                                    height: 0,
                                    color: isDark ? null : Colors.black12,
                                  ),
                                  HabitStartAtWidget(
                                    habitStartAt:
                                        AppConverters.stringToDateTime(
                                          habit.habitStartAt,
                                        ),
                                    isDark: isDark,
                                  ),
                                  Divider(
                                    height: 0,
                                    color: isDark ? null : Colors.black12,
                                  ),
                                  DurationWidget(habitEndAt: habit.habitEndAt),
                                  Divider(
                                    height: 0,
                                    color: isDark ? null : Colors.black12,
                                  ),

                                  HabitRemainderWidget(
                                    time: habit.habitRemindTime,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        AddNoteWidget(
                          isDark: isDark,
                          noteController: noteController,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } else if (state is CreateLoading) {
          return const AppLoading();
        } else {
          return const AppLoading();
        }
      },
    );
  }

  void _createHabit(BuildContext context, Habit habit, bool isUpdate) {
    final newHabit = Habit(
      id: isUpdate ? habit.id : DateTime.now().toString(),
      habitName: nameController.text.trim(),
      habitColorId: habit.habitColorId,
      habitEndAt: habit.habitEndAt ?? 'Off',
      habitIconId: habit.habitIconId,
      category: habit.category,
      habitRemindTime: habit.habitRemindTime ?? 'Off',
      habitRepeatValue: habit.habitRepeatValue ?? 'Daily',
      habitStartAt: habit.habitStartAt ?? 'Today',
      habitTime: habit.habitTime ?? 'Anytime',
      note: noteController.text.trim(),
      repeatDays: habit.repeatDays,
      isCompleteToday: habit.isCompleteToday,
    );
    if (isUpdate) {
      context.read<HabitsBloc>().add(UpdateHabitEvent(newHabit));
    } else {
      context.read<HabitsBloc>().add(AddHabitEvent(newHabit));
    }
    Navigator.pop(context);
    if (widget.icon == null && widget.name == null) {
      Navigator.pop(context);
    }
    context.read<HabitsBloc>().add(BottomNavScreenChangeEvent(index: 0));
  }
}
