// lib/features/settings/presentation/bloc/apptheme_event.dart
part of 'apptheme_bloc.dart';

@immutable
sealed class ThemeEvent {}

/// Load the previously saved theme index (and optional custom config) from
/// SharedPreferences on app start.
final class LoadSavedTheme extends ThemeEvent {}

/// Switch to one of the built-in themes by index.
/// Also clears any active custom theme data from state.
final class ChangeTheme extends ThemeEvent {
  final int themeIndex;
   ChangeTheme(this.themeIndex);
}

/// Build, persist, and activate a custom theme from a [CustomThemeModel].
final class ApplyCustomTheme extends ThemeEvent {
  final CustomThemeModel model;
   ApplyCustomTheme(this.model);
}

/// Deactivate the custom theme when a subscription expires.
///
/// Switches the active theme to index 0 but deliberately preserves
/// [ThemeState.customThemeModel] so it can be restored when the user
/// re-subscribes — without them having to reconfigure anything.
final class DeactivateCustomTheme extends ThemeEvent {
   DeactivateCustomTheme();
}