// lib/features/diary/presentation/blocs/showcase/showcase_state.dart

part of 'showcase_cubit.dart';

class ShowcaseState {
  /// null = not yet checked, true = show, false = already seen
  final bool? shouldShow;
  const ShowcaseState({this.shouldShow});
}