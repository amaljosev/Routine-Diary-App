import 'dart:async';
import 'package:consist/core/app_colors.dart';
import 'package:consist/core/constants/habits_items.dart';
import 'package:consist/core/utils/common_functions.dart';
import 'package:consist/features/habit/domain/create_habit/entities/habit_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'create_event.dart';
part 'create_state.dart';

class CreateBloc extends Bloc<CreateEvent, CreateState> {
  CreateBloc() : super(CreateInitial(habit: _createInitialHabit())) {
    on<InitializeCreateEvent>(_onInitialize);
    on<UpdateHabitNameEvent>(_onUpdateHabitName);
    on<UpdateHabitNoteEvent>(_onUpdateHabitNote);
    on<UpdateHabitIconEvent>(_onUpdateHabitIconId);
    on<UpdateHabitColorEvent>(_onUpdateHabitColorId);
    on<UpdateHabitStartAtEvent>(_onUpdateHabitStartAt);
    on<UpdateHabitTimeEvent>(_onUpdateHabitTime);
    on<UpdateHabitGoalValueEvent>(_onUpdateHabitGoalValue);
    on<UpdateHabitGoalCountEvent>(_onUpdateHabitGoalCount);
    on<UpdateHabitCategoryEvent>(_onUpdateHabitCategory);
    on<UpdateHabitEndAtEvent>(_onUpdateHabitEndAt);
    on<UpdateHabitRepeatValueEvent>(_onUpdateHabitRepeatValue);
    on<UpdateRepeatDaysEvent>(_onUpdateRepeatDays);
    on<UpdateHabitRemindTimeEvent>(_onUpdateHabitRemindTime);
    on<SaveHabitEvent>(_onSaveHabit);
    on<ResetCreateEvent>(_onReset);
  }

  static Habit _createInitialHabit() {
    return Habit(
      id: null,
      habitName: null,
      note: null,
      habitIconId: CommonFunctions.getRandomNumber(
        0,
        HabitsItems.habitList.length - 1,
      ).toString(),
      habitStartAt: null,
      habitTime: null,
      habitEndAt: null,
      habitRepeatValue: null,
      repeatDays: null,
      habitRemindTime: null,
      goalValue: null,
      goalCount: null,
      habitColorId: CommonFunctions.getRandomNumber(
        0,
        AppColors.myColors.length - 1,
      ).toString(),
    );
  }

  Future<void> _onInitialize(
    InitializeCreateEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      if (event.habit != null) {
        emit(CreateInitial(habit: event.habit!));
      } else {
        emit(
          CreateInitial(
            habit: currentState.habit.copyWith(
            
              category: event.category,
              habitIconId:
                  event.iconId ??
                  CommonFunctions.getRandomNumber(
                    0,
                    HabitsItems.habitList.length - 1,
                  ).toString(),
              habitColorId: CommonFunctions.getRandomNumber(
                0,
                AppColors.myColors.length - 1,
              ).toString(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _onUpdateHabitName(
    UpdateHabitNameEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(habitName: event.habitName),
        ),
      );
    }
  }

  Future<void> _onUpdateHabitNote(
    UpdateHabitNoteEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(CreateInitial(habit: currentState.habit.copyWith(note: event.note)));
    }
  }

  Future<void> _onUpdateHabitIconId(
    UpdateHabitIconEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(habitIconId: event.icon),
        ),
      );
    }
  }

  // Future<void> _onUpdateHabitType(
  //   UpdateHabitTypeEvent event,
  //   Emitter<CreateState> emit,
  // ) async {
  //   final currentState = state;
  //   if (currentState is CreateInitial) {
  //     emit(
  //       CreateInitial(
  //         habit: currentState.habit.copyWith(habitType: event.type),
  //       ),
  //     );
  //   }
  // }

  Future<void> _onUpdateHabitColorId(
    UpdateHabitColorEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(habitColorId: event.color),
        ),
      );
    }
  }

  Future<void> _onUpdateHabitStartAt(
    UpdateHabitStartAtEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(habitStartAt: event.startAt),
        ),
      );
    }
  }

  Future<void> _onUpdateHabitTime(
    UpdateHabitTimeEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(habitTime: event.time),
        ),
      );
    }
  }

  Future<void> _onUpdateHabitEndAt(
    UpdateHabitEndAtEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(habitEndAt: event.endAt),
        ),
      );
    }
  }

  Future<void> _onUpdateHabitRepeatValue(
    UpdateHabitRepeatValueEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(
            habitRepeatValue: event.repeatValue,
          ),
        ),
      );
    }
  }

  Future<void> _onUpdateRepeatDays(
    UpdateRepeatDaysEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(repeatDays: event.repeatDays),
        ),
      );
    }
  }

  Future<void> _onUpdateHabitRemindTime(
    UpdateHabitRemindTimeEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(habitRemindTime: event.remindTime),
        ),
      );
    }
  }

  Future<void> _onSaveHabit(
    SaveHabitEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      final habit = currentState.habit;

      // Validation
      if (habit.habitName == null || habit.habitName!.isEmpty) {
        emit(CreateValidationError('habitName', 'Habit name is required'));
        return;
      }

      if (habit.habitIconId == null) {
        emit(CreateValidationError('habitIconId', 'Please select an icon'));
        return;
      }

      emit(CreateLoading());

      try {
        // Here you would save to database/local storage
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Simulate save

        // Emit success and reset
        emit(CreateSuccess('Habit created successfully'));

        // Reset to initial state after success
        add(ResetCreateEvent());
      } catch (e) {
        emit(CreateError('Failed to save habit: $e'));
      }
    }
  }

  Future<void> _onReset(
    ResetCreateEvent event,
    Emitter<CreateState> emit,
  ) async {
    emit(CreateInitial(habit: _createInitialHabit()));
  }

  FutureOr<void> _onUpdateHabitCategory(
    UpdateHabitCategoryEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(category: event.category),
        ),
      );
    }
  }

  FutureOr<void> _onUpdateHabitGoalValue(
    event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(goalValue: event.goalValue),
        ),
      );
    }
  }

  FutureOr<void> _onUpdateHabitGoalCount(
    UpdateHabitGoalCountEvent event,
    Emitter<CreateState> emit,
  ) async {
    final currentState = state;
    if (currentState is CreateInitial) {
      emit(
        CreateInitial(
          habit: currentState.habit.copyWith(goalCount: event.goalCount),
        ),
      );
    }
  }
}
