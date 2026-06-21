part of 'apptheme_bloc.dart';

abstract class ThemeEvent {}

/// Existing events – unchanged.
class LoadSavedTheme extends ThemeEvent {}

class ChangeTheme extends ThemeEvent {
  final int themeIndex;
  ChangeTheme(this.themeIndex);
}

/// New: apply and persist a custom theme configuration.
class ApplyCustomTheme extends ThemeEvent {
  final CustomThemeModel model;
  ApplyCustomTheme(this.model);
}