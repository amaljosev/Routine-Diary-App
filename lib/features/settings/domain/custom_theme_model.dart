import 'dart:convert';
import 'package:flutter/material.dart';

/// Sentinel index used in SharedPreferences to indicate the custom theme is active.
/// Must be > allThemes.length - 1 (currently 6), so 99 is safe.
const int kCustomThemeIndex = 99;

/// Palette selection inside the custom theme editor.
/// [builtIn] = one of the 7 hard-coded palettes (0-6).
/// [custom]  = user-defined colors via CustomColorScreen.
enum PaletteType { builtIn, custom }

/// All colors needed to reconstruct a full ThemeData for the app.
/// Mirrors exactly the color fields used in app_theme.dart.
class CustomColorSet {
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color background; // scaffoldBackgroundColor
  final Color onBackground; // onSurface / text color
  final Color error;
  final bool isDark;

  const CustomColorSet({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.isDark,
  });

  /// Default: copy of theme index 0 (lightTheme2 – Purple/Teal).
  factory CustomColorSet.defaultColors() => const CustomColorSet(
        primary: Color(0xFF1976D2),   // light1Primary
        secondary: Color(0xFFFF6F00), // light1Secondary
        surface: Color(0xFFFFFFFF),
        background: Color(0xFFE3F2FD),
        onBackground: Color(0xFF1A1A1A),
        error: Color(0xFFC62828),
        isDark: false,
      );

  Map<String, dynamic> toMap() => {
        'primary': primary.toARGB32(),
        'secondary': secondary.toARGB32(),
        'surface': surface.toARGB32(),
        'background': background.toARGB32(),
        'onBackground': onBackground.toARGB32(),
        'error': error.toARGB32(),
        'isDark': isDark,
      };

  factory CustomColorSet.fromMap(Map<String, dynamic> map) => CustomColorSet(
        primary: Color(map['primary'] as int),
        secondary: Color(map['secondary'] as int),
        surface: Color(map['surface'] as int),
        background: Color(map['background'] as int),
        onBackground: Color(map['onBackground'] as int),
        error: Color(map['error'] as int),
        isDark: map['isDark'] as bool,
      );

  CustomColorSet copyWith({
    Color? primary,
    Color? secondary,
    Color? surface,
    Color? background,
    Color? onBackground,
    Color? error,
    bool? isDark,
  }) =>
      CustomColorSet(
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        surface: surface ?? this.surface,
        background: background ?? this.background,
        onBackground: onBackground ?? this.onBackground,
        error: error ?? this.error,
        isDark: isDark ?? this.isDark,
      );
}

/// The persisted configuration for the user's custom theme.
class CustomThemeModel {
  /// Absolute file-system path to the cropped header image, OR
  /// an asset path prefixed with 'assets/' if an asset was chosen.
  final String headerImagePath;

  final PaletteType paletteType;

  /// Index into allThemes (0-6) when paletteType == builtIn.
  final int builtInPaletteIndex;

  /// Non-null when paletteType == custom.
  final CustomColorSet? customColors;

  const CustomThemeModel({
    required this.headerImagePath,
    required this.paletteType,
    required this.builtInPaletteIndex,
    this.customColors,
  });

  /// Default state: everything from theme index 0.
  factory CustomThemeModel.defaultModel() => const CustomThemeModel(
        headerImagePath: 'assets/img/themes/theme_2.webp',
        paletteType: PaletteType.builtIn,
        builtInPaletteIndex: 0,
      );

  Map<String, dynamic> toMap() => {
        'headerImagePath': headerImagePath,
        'paletteType': paletteType.name,
        'builtInPaletteIndex': builtInPaletteIndex,
        'customColors':
            customColors != null ? jsonEncode(customColors!.toMap()) : null,
      };

  factory CustomThemeModel.fromMap(Map<String, dynamic> map) =>
      CustomThemeModel(
        headerImagePath: map['headerImagePath'] as String,
        paletteType: PaletteType.values.firstWhere(
          (e) => e.name == map['paletteType'],
          orElse: () => PaletteType.builtIn,
        ),
        builtInPaletteIndex: map['builtInPaletteIndex'] as int,
        customColors: map['customColors'] != null
            ? CustomColorSet.fromMap(
                jsonDecode(map['customColors'] as String)
                    as Map<String, dynamic>,
              )
            : null,
      );

  String toJson() => jsonEncode(toMap());

  factory CustomThemeModel.fromJson(String source) =>
      CustomThemeModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  CustomThemeModel copyWith({
    String? headerImagePath,
    PaletteType? paletteType,
    int? builtInPaletteIndex,
    CustomColorSet? customColors,
    bool clearCustomColors = false,
  }) =>
      CustomThemeModel(
        headerImagePath: headerImagePath ?? this.headerImagePath,
        paletteType: paletteType ?? this.paletteType,
        builtInPaletteIndex: builtInPaletteIndex ?? this.builtInPaletteIndex,
        customColors:
            clearCustomColors ? null : (customColors ?? this.customColors),
      );
}