part of 'apptheme_bloc.dart';

class ThemeState {
  final int themeIndex;

  /// Non-null only when [themeIndex] == [kCustomThemeIndex].
  final CustomThemeModel? customThemeModel;

  /// Pre-built ThemeData for the custom theme so MyApp doesn't need to rebuild it.
  final ThemeData? customThemeData;

  const ThemeState({
    required this.themeIndex,
    this.customThemeModel,
    this.customThemeData,
  });

  factory ThemeState.initial() => const ThemeState(themeIndex: 0);

  bool get isCustomThemeActive => themeIndex == kCustomThemeIndex;

  ThemeState copyWith({
    int? themeIndex,
    CustomThemeModel? customThemeModel,
    ThemeData? customThemeData,
    bool clearCustomTheme = false,
  }) {
    return ThemeState(
      themeIndex: themeIndex ?? this.themeIndex,
      customThemeModel:
          clearCustomTheme ? null : (customThemeModel ?? this.customThemeModel),
      customThemeData:
          clearCustomTheme ? null : (customThemeData ?? this.customThemeData),
    );
  }
}