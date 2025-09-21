part of 'create_bloc.dart';

@immutable
abstract class CreateState extends Equatable {
  const CreateState();

  @override
  List<Object?> get props => [];
}

class CreateInitial extends CreateState {
  final Habit habit;

  const CreateInitial({required this.habit});

  @override
  List<Object?> get props => [habit];
}


class CreateLoading extends CreateState {}

class CreateSuccess extends CreateState {
  final String message;

  const CreateSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CreateError extends CreateState {
  final String message;

  const CreateError(this.message);

  @override
  List<Object?> get props => [message];
}

class CreateValidationError extends CreateState {
  final String field;
  final String message;

  const CreateValidationError(this.field, this.message);

  @override
  List<Object?> get props => [field, message];
}