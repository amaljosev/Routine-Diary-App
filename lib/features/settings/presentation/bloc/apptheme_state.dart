// lib/features/settings/presentation/bloc/apptheme_state.dart
part of 'apptheme_bloc.dart';

/// Index used when the custom theme is the active theme.
const int kCustomThemeIndex = 7;

@immutable
class ThemeState {
  final int themeIndex;

  /// The Flutter ThemeData built from [customThemeModel]. Only non-null when
  /// the custom theme is currently active (themeIndex == kCustomThemeIndex).
  final ThemeData? customThemeData;

  /// The user's saved custom theme configuration.
  ///
  /// KEY INVARIANT: this field is NEVER cleared when the user picks a
  /// built-in theme or when a subscription expires. It is only cleared if
  /// the user explicitly resets / deletes their custom theme. This allows
  /// the "Restore Custom Theme" button to keep working after a plan change.
  final CustomThemeModel? customThemeModel;

  const ThemeState({
    required this.themeIndex,
    this.customThemeData,
    this.customThemeModel,
  });

  factory ThemeState.initial() => const ThemeState(themeIndex: 0);

  bool get isCustomThemeActive => themeIndex == kCustomThemeIndex;

  ThemeState copyWith({
    int? themeIndex,
    ThemeData? customThemeData,
    CustomThemeModel? customThemeModel,
    // When true, clears the ACTIVE custom theme display (customThemeData)
    // but intentionally leaves customThemeModel intact so the saved config
    // survives built-in theme switches.
    bool clearActiveCustomTheme = false,
    // Only set true when the user explicitly deletes their custom theme.
    bool clearCustomThemeModel = false,
  }) {
    return ThemeState(
      themeIndex: themeIndex ?? this.themeIndex,
      customThemeData: clearActiveCustomTheme
          ? null
          : (customThemeData ?? this.customThemeData),
      customThemeModel: clearCustomThemeModel
          ? null
          : (customThemeModel ?? this.customThemeModel),
    );
  }
}