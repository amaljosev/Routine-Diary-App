part of 'create_bloc.dart';

@immutable
abstract class CreateEvent extends Equatable {
  const CreateEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCreateEvent extends CreateEvent {
  final String category;
  final Habit? habit;
  final String? iconId;

  const InitializeCreateEvent({
    required this.category,
    this.habit,
    this.iconId,
  });

  @override
  List<Object?> get props => [category,];
}

class UpdateHabitNameEvent extends CreateEvent {
  final String habitName;

  const UpdateHabitNameEvent(this.habitName);

  @override
  List<Object?> get props => [habitName];
}

class UpdateHabitNoteEvent extends CreateEvent {
  final String note;

  const UpdateHabitNoteEvent(this.note);

  @override
  List<Object?> get props => [note];
}

class UpdateHabitCategoryEvent extends CreateEvent {
  final String category;

  const UpdateHabitCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class UpdateHabitIconEvent extends CreateEvent {
  final String icon;

  const UpdateHabitIconEvent(this.icon);

  @override
  List<Object?> get props => [icon];
}

class UpdateHabitTypeEvent extends CreateEvent {
  final String type;

  const UpdateHabitTypeEvent(this.type);

  @override
  List<Object?> get props => [type];
}

class UpdateHabitColorEvent extends CreateEvent {
  final String color;

  const UpdateHabitColorEvent(this.color);

  @override
  List<Object?> get props => [color];
}

class UpdateHabitStartAtEvent extends CreateEvent {
  final String startAt;

  const UpdateHabitStartAtEvent(this.startAt);

  @override
  List<Object?> get props => [startAt];
}

class UpdateHabitTimeEvent extends CreateEvent {
  final String time;

  const UpdateHabitTimeEvent(this.time);

  @override
  List<Object?> get props => [time];
}

class UpdateHabitEndAtEvent extends CreateEvent {
  final String endAt;

  const UpdateHabitEndAtEvent(this.endAt);

  @override
  List<Object?> get props => [endAt];
}

class UpdateHabitRepeatValueEvent extends CreateEvent {
  final String repeatValue;

  const UpdateHabitRepeatValueEvent(this.repeatValue);

  @override
  List<Object?> get props => [repeatValue];
}

class UpdateHabitGoalValueEvent extends CreateEvent {
  final String goalValue;

  const UpdateHabitGoalValueEvent(this.goalValue);

  @override
  List<Object?> get props => [goalValue];
}

class UpdateHabitGoalCountEvent extends CreateEvent {
  final String goalCount;

  const UpdateHabitGoalCountEvent(this.goalCount);

  @override
  List<Object?> get props => [goalCount];
}

class UpdateRepeatDaysEvent extends CreateEvent {
  final String repeatDays;

  const UpdateRepeatDaysEvent(this.repeatDays);

  @override
  List<Object?> get props => [repeatDays];
}

class UpdateHabitRemindTimeEvent extends CreateEvent {
  final String? remindTime;

  const UpdateHabitRemindTimeEvent(this.remindTime);

  @override
  List<Object?> get props => [remindTime];
}

class SaveHabitEvent extends CreateEvent {}

class ResetCreateEvent extends CreateEvent {}
