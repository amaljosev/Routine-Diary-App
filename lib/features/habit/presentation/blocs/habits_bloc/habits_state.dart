part of 'habits_bloc.dart';

abstract class HabitsState extends Equatable {
  const HabitsState();

  @override
  List<Object?> get props => [];
}

class HabitsInitial extends HabitsState {}

class HabitsLoading extends HabitsState {}

class HabitsLoaded extends HabitsState {
  final List<Habit> habits;
  final List<Habit> filtered;
  final String cat;
  const HabitsLoaded({
    required this.habits,
    this.cat = '0',
    required this.filtered,
  });
  HabitsLoaded copyWith({
    List<Habit>? habits,
    List<Habit>? filtered,
    String? cat,
  }) {
    return HabitsLoaded(
      habits: habits ?? this.habits,
      filtered: filtered ?? this.filtered,
      cat: cat ?? this.cat,
    );
  }

  @override
  List<Object?> get props => [habits, cat, filtered];
}

class HabitsError extends HabitsState {
  final String message;
  const HabitsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class BottomNavScreenChangeState extends HabitsState {
  final int index;
  const BottomNavScreenChangeState({required this.index});

  @override
  List<Object?> get props => [index];
}

class HabitCompleteSuccess extends HabitsState {}

class HabitCompleteError extends HabitsState {}
class HabitAnalyticsLoading extends HabitsState {}

class HabitAnalyticsLoaded extends HabitsState {
  final HabitAnalytics? analytics;
  const HabitAnalyticsLoaded({required this.analytics});

  @override
  List<Object?> get props => [analytics];
}

class HabitAnalyticsError extends HabitsState {
  final String message;
  const HabitAnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
class UpdateHabitGoalCountSuccess extends HabitsState {}
class UpdateHabitGoalCountError extends HabitsState {
  final String message;
  const UpdateHabitGoalCountError(this.message);

  @override
  List<Object?> get props => [message];
}
class IncrementHabitGoalCountSuccess extends HabitsState {}

class IncrementHabitGoalCountError extends HabitsState {
  final String message;
  const IncrementHabitGoalCountError(this.message);
  @override
  List<Object?> get props => [message];
}

class DecrementHabitGoalCountSuccess extends HabitsState {}

class DecrementHabitGoalCountError extends HabitsState {
  final String message;
  const DecrementHabitGoalCountError(this.message);
  @override
  List<Object?> get props => [message];
}
class ResetHabitGoalCountSuccess extends HabitsState {}
class ResetHabitGoalCountError extends HabitsState {
  final String message;
  const ResetHabitGoalCountError(this.message);

  @override
  List<Object?> get props => [message];
}