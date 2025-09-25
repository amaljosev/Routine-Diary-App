part of 'habits_bloc.dart';

abstract class HabitsEvent extends Equatable {
  const HabitsEvent();

  @override
  List<Object?> get props => [];
}

class InitialEvent extends HabitsEvent {}

class BottomNavScreenChangeEvent extends HabitsEvent {
  final int index;
  const BottomNavScreenChangeEvent({required this.index});

  @override
  List<Object?> get props => [index];
}

class LoadHabitsEvent extends HabitsEvent {}

class AddHabitEvent extends HabitsEvent {
  final Habit habit;
  const AddHabitEvent(this.habit);

  @override
  List<Object?> get props => [habit];
}

class UpdateHabitEvent extends HabitsEvent {
  final Habit habit;
  const UpdateHabitEvent(this.habit);

  @override
  List<Object?> get props => [habit];
}

class DeleteHabitEvent extends HabitsEvent {
  final String id;
  const DeleteHabitEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkHabitCompleteEvent extends HabitsEvent {
  final String habitId;

  const MarkHabitCompleteEvent({required this.habitId});

  @override
  List<Object?> get props => [habitId];
}

class FetchHabitsByCategory extends HabitsEvent {
  final String category;
  const FetchHabitsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}
class FetchHabitAnalyticsEvent extends HabitsEvent {
  final String habitId;
  const FetchHabitAnalyticsEvent(this.habitId);

  @override
  List<Object?> get props => [habitId];
}
class UpdateHabitGoalCountEvent extends HabitsEvent {
  final String habitId;
  final int count;
  const UpdateHabitGoalCountEvent({required this.habitId, this.count = 1});

  @override
  List<Object?> get props => [habitId, count];
}
class IncrementHabitGoalCountEvent extends HabitsEvent {
  final String habitId;
  const IncrementHabitGoalCountEvent({required this.habitId});

  @override
  List<Object?> get props => [habitId];
}
class DecrementHabitGoalCountEvent extends HabitsEvent {
  final String habitId;
  const DecrementHabitGoalCountEvent({required this.habitId});

  @override
  List<Object?> get props => [habitId];
}
class ResetHabitGoalCountEvent extends HabitsEvent {
  final String habitId;
  const ResetHabitGoalCountEvent({required this.habitId});

  @override
  List<Object?> get props => [habitId];
}