import 'package:consist/features/habit/domain/create_habit/entities/analytics_models.dart';
import 'package:consist/features/habit/domain/create_habit/entities/habit_model.dart';
import 'package:consist/features/habit/domain/create_habit/repositories/habit_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'habits_event.dart';
part 'habits_state.dart';

class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  final HabitRepository habitRepository;

  HabitsBloc({required this.habitRepository}) : super(HabitsInitial()) {
    // Load all habits on load event
    on<LoadHabitsEvent>((event, emit) async {
      emit(HabitsLoading());
      try {
        final habits = await habitRepository.getAllHabits();
        emit(HabitsLoaded(habits: habits, filtered: habits, cat: "0"));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    });

    // Add new habit event
    on<AddHabitEvent>((event, emit) async {
      try {
        await habitRepository.createHabit(event.habit);
        final habits = await habitRepository.getAllHabits();
        emit(HabitsLoaded(habits: habits, filtered: habits, cat: "0"));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    });

    // Update habit event
    on<UpdateHabitEvent>((event, emit) async {
      try {
        emit(HabitsLoading());
        await habitRepository.updateHabit(event.habit);
        final habits = await habitRepository.getAllHabits();
        emit(HabitsLoaded(habits: habits, filtered: habits, cat: "0"));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    });

    // Delete habit event
    on<DeleteHabitEvent>((event, emit) async {
      try {
        await habitRepository.deleteHabit(event.id);
        final habits = await habitRepository.getAllHabits();
        emit(HabitsLoaded(habits: habits, filtered: habits, cat: "0"));
      } catch (e) {
        emit(HabitsError(message: e.toString()));
      }
    });

    // Bottom navigation screen change event
    on<BottomNavScreenChangeEvent>(
      (event, emit) => emit(BottomNavScreenChangeState(index: event.index)),
    );

    // Mark habit complete event
    on<MarkHabitCompleteEvent>((event, emit) async {
      emit(HabitsLoading());
      try {
        final todayStr =
            "${DateTime.now().day}:${DateTime.now().month}:${DateTime.now().year}";
        final analytics = await habitRepository.updateHabitAnalytics(
          event.habitId,
        );
        await habitRepository.markHabitComplete(
          habitId: event.habitId,
          completionDate: todayStr,
          analytics: analytics!,
          isComplete: true,
        );

        emit(HabitCompleteSuccess());
      } catch (e) {
        emit(HabitsError(message: 'Failed to mark habit complete: $e'));
      }
    });

    // Handle category filter event
    on<FetchHabitsByCategory>((event, emit) {
      if (state is HabitsLoaded) {
        final currentState = state as HabitsLoaded;
        final allHabits = currentState.habits;

        final filteredHabits = (event.category.toLowerCase() == "0")
            ? allHabits
            : allHabits
                  .where((habit) => habit.category == event.category)
                  .toList();

        emit(
          currentState.copyWith(
            cat: event.category,
            filtered: filteredHabits,
            habits: allHabits,
          ),
        );
      }
    });
    on<FetchHabitAnalyticsEvent>((event, emit) async {
      emit(HabitAnalyticsLoading());
      try {
        // Fetch analytics by habitId from repository
        final analytics = await habitRepository.checkStreakAndFetchAnalytics(
          event.habitId,
        );

        emit(HabitAnalyticsLoaded(analytics: analytics));
      } catch (e) {
        emit(HabitAnalyticsError(e.toString()));
      }
    });

    on<ResetHabitGoalCountEvent>((event, emit) async {
      try {
        final result = await habitRepository.resetHabitGoalCount(event.habitId);
        if (result != -1) {
          emit(ResetHabitGoalCountSuccess());
        } else {
          emit(ResetHabitGoalCountError('Failed to reset goal count'));
        }
      } catch (e) {
        emit(
          ResetHabitGoalCountError(
            'Failed to reset goal count: ${e.toString()}',
          ),
        );
      }
    });
    on<UpdateHabitGoalCountEvent>((event, emit) async {
      try {
        final result = await habitRepository.updateHabitGoalCount(
          event.habitId,
          event.count,
        );
        if (result != -1) {
          emit(UpdateHabitGoalCountSuccess());
        } else {
          emit(HabitsError(message: 'Failed to update goal count'));
        }
      } catch (e) {
        emit(
          HabitsError(message: 'Failed to update goal count: ${e.toString()}'),
        );
      }
    });
    on<IncrementHabitGoalCountEvent>((event, emit) async {
  try {
    final result = await habitRepository.incrementHabitGoalCount(event.habitId);
    if (result != -1) {
      emit(IncrementHabitGoalCountSuccess()); 
    } else {
      emit(IncrementHabitGoalCountError('Failed to increment goal count'));
    }
  } catch (e) {
    emit(IncrementHabitGoalCountError('Failed to increment goal count: $e'));
  }
});

on<DecrementHabitGoalCountEvent>((event, emit) async {
  try {
    final result = await habitRepository.decrementHabitGoalCount(event.habitId);
    if (result != -1) {
      emit(DecrementHabitGoalCountSuccess()); 
    } else {
      emit(DecrementHabitGoalCountError('Failed to decrement goal count'));
    }
  } catch (e) {
    emit(DecrementHabitGoalCountError('Failed to decrement goal count: $e'));
  }
});

  }
}
