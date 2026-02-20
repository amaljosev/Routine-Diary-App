part of 'apptheme_bloc.dart';

class ThemeState {
  final int themeIndex; 

  ThemeState({required this.themeIndex});

  factory ThemeState.initial() => ThemeState(themeIndex: 0);

  ThemeState copyWith({int? themeIndex}) {
    return ThemeState(themeIndex: themeIndex ?? this.themeIndex);
  }
}