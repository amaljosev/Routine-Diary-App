import 'package:flutter/material.dart';
import 'package:routine/core/theme/app_colors.dart';
import 'package:routine/core/theme/app_theme.dart';
import 'package:routine/core/theme/theme_extenstions.dart';
import 'custom_theme_model.dart';


ThemeData buildCustomThemeData(CustomThemeModel model) {
  final colors = _resolveColors(model);
  final base =
      colors.isDark ? ThemeData.dark() : ThemeData.light();

  return base.copyWith(
    primaryColor: colors.primary,
    scaffoldBackgroundColor: colors.background,

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.primary,
      foregroundColor: Colors.white,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor:
          colors.isDark ? colors.surface : colors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontFamily: 'Quicksand',
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: Colors.white,
      ),
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w700,
          color: colors.onBackground),
      displayMedium: TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w600,
          color: colors.onBackground),
      displaySmall: TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w600,
          color: colors.onBackground),
      headlineLarge: TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w600,
          color: colors.onBackground),
      headlineMedium: TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w500,
          color: colors.onBackground),
      headlineSmall: TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w500,
          color: colors.onBackground),
      titleLarge: TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w500,
          color: colors.onBackground),
      titleMedium: TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w500,
          color: colors.onBackground),
      titleSmall: TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w400,
          color: colors.onBackground),
      bodyLarge: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: colors.onBackground),
      bodyMedium: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w500,
          color: colors.onBackground),
      bodySmall: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w400,
          color: colors.onBackground),
      labelLarge: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: Colors.white),
      labelMedium: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w500,
          color: Colors.white),
      labelSmall: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w500,
          color: Colors.white),
    ),

    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      indicator: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      splashBorderRadius: const BorderRadius.all(Radius.circular(20)),
      labelStyle: TextStyle(
        fontFamily: 'Quicksand',
        fontWeight: FontWeight.w600,
        color: colors.background,
      ),
    ),

    colorScheme: colors.isDark
        ? ColorScheme.dark(
            primary: colors.primary,
            secondary: colors.secondary,
            surface: colors.surface,
            onPrimary: Colors.white,
            onSurface: colors.onBackground,
            error: colors.error,
          )
        : ColorScheme.light(
            primary: colors.primary,
            secondary: colors.secondary,
            surface: colors.surface,
            onPrimary: Colors.white,
            onSurface: colors.onBackground,
            error: colors.error,
          ),

    extensions: [
      BackgroundImageTheme(imagePath: model.headerImagePath),
    ],
  );
}

/// Returns the color set for the given model.
/// If paletteType == builtIn, we copy colors from the matching allThemes entry.
/// If paletteType == custom, we use the custom color set directly.
CustomColorSet _resolveColors(CustomThemeModel model) {
  if (model.paletteType == PaletteType.custom &&
      model.customColors != null) {
    return model.customColors!;
  }
  return _colorsFromBuiltIn(model.builtInPaletteIndex);
}

/// Extracts a [CustomColorSet] from one of the built-in allThemes entries.
CustomColorSet _colorsFromBuiltIn(int index) {
  final safeIndex = index.clamp(0, allThemes.length - 1);
  final theme = allThemes[safeIndex];
  final cs = theme.colorScheme;
  return CustomColorSet(
    primary: cs.primary,
    secondary: cs.secondary,
    surface: cs.surface,
    background: theme.scaffoldBackgroundColor,
    onBackground: cs.onSurface,
    error: cs.error,
    isDark: cs.brightness == Brightness.dark,
  );
}

/// Palette display info used in CustomThemeScreen.
class PaletteInfo {
  final int index; // 0-6 = built-in, -1 = custom
  final String label;
  final Color primary;
  final Color secondary;
  final Color background;
  final bool isDark;

  const PaletteInfo({
    required this.index,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.isDark,
  });
}

const List<String> kBuiltInPaletteNames = [
  'Purple Teal',
  'Blue Orange',
  'Green Coral',
  'Orange Purple',
  'Deep Purple (Dark)',
  'Blue Grey (Dark)',
  'Forest Green (Dark)',
];

List<PaletteInfo> buildPaletteInfoList() {
  return [
    PaletteInfo(
      index: 0,
      label: kBuiltInPaletteNames[0],
      primary: AppColors.light1Primary,
      secondary: AppColors.light1Secondary,
      background: AppColors.light1Background,
      isDark: false,
    ),
    PaletteInfo(
      index: 1,
      label: kBuiltInPaletteNames[1],
      primary: AppColors.light2Primary,
      secondary: AppColors.light2Secondary,
      background: AppColors.light2Background,
      isDark: false,
    ),
    PaletteInfo(
      index: 2,
      label: kBuiltInPaletteNames[2],
      primary: AppColors.light3Primary,
      secondary: AppColors.light3Secondary,
      background: AppColors.light3Background,
      isDark: false,
    ),
    PaletteInfo(
      index: 3,
      label: kBuiltInPaletteNames[3],
      primary: AppColors.light4Primary,
      secondary: AppColors.light4Secondary,
      background: AppColors.light4Background,
      isDark: false,
    ),
    PaletteInfo(
      index: 4,
      label: kBuiltInPaletteNames[4],
      primary: AppColors.dark1Primary,
      secondary: AppColors.dark1Secondary,
      background: AppColors.dark1Background,
      isDark: true,
    ),
    PaletteInfo(
      index: 5,
      label: kBuiltInPaletteNames[5],
      primary: AppColors.dark2Primary,
      secondary: AppColors.dark2Secondary,
      background: AppColors.dark2Background,
      isDark: true,
    ),
    PaletteInfo(
      index: 6,
      label: kBuiltInPaletteNames[6],
      primary: AppColors.dark3Primary,
      secondary: AppColors.dark3Secondary,
      background: AppColors.dark3Background,
      isDark: true,
    ),
  ];
}