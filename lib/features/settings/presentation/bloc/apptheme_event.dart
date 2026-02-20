part of 'apptheme_bloc.dart';

abstract class ThemeEvent {}

class LoadSavedTheme extends ThemeEvent {}

class ChangeTheme extends ThemeEvent {
  final int themeIndex;
  ChangeTheme(this.themeIndex);
}