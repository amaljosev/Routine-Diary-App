import 'package:flutter/material.dart';
import 'package:routine/core/theme/app_colors.dart';
import 'package:routine/core/theme/theme_extenstions.dart';

final ThemeData lightTheme1 = ThemeData.light().copyWith(
  primaryColor: AppColors.light1Primary,
  scaffoldBackgroundColor: AppColors.light1Background,

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.light1Primary,
    foregroundColor: Colors.white,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.light1Primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.white,
    ),
  ),

  textTheme: const TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w700,
      color: AppColors.light1OnBackground,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light1OnBackground,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light1OnBackground,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light1OnBackground,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light1OnBackground,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light1OnBackground,
    ),

    // Titles
    titleLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light1OnBackground,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light1OnBackground,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w400,
      color: AppColors.light1OnBackground,
    ),

    // Body (Nunito)
    bodyLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: AppColors.light1OnBackground,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: AppColors.light1OnBackground,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w400,
      color: AppColors.light1OnBackground,
    ),

    // Labels & Buttons (Nunito)
    labelLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
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
      color: AppColors.light1Background,
    ),
  ),

  colorScheme: const ColorScheme.light(
    primary: AppColors.light1Primary,
    secondary: AppColors.light1Secondary,
    surface: AppColors.light1Surface,
    onPrimary: Colors.white,
    onSurface: AppColors.light1OnBackground,
    error: AppColors.light1Error,
  ),

  // Add background image
  extensions: [
    const BackgroundImageTheme(imagePath: 'assets/img/themes/theme_1.png'),
  ],
);

// ----- LIGHT THEME 2: Blue/Orange (Vibrant) -----
final ThemeData lightTheme2 = ThemeData.light().copyWith(
  primaryColor: AppColors.light2Primary,
  scaffoldBackgroundColor: AppColors.light2Background,

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.light2Primary,
    foregroundColor: Colors.white,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.light2Primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.white,
    ),
  ),

  textTheme: const TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w700,
      color: AppColors.light2OnBackground,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light2OnBackground,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light2OnBackground,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light2OnBackground,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light2OnBackground,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light2OnBackground,
    ),

    // Titles
    titleLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light2OnBackground,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light2OnBackground,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w400,
      color: AppColors.light2OnBackground,
    ),

    // Body (Nunito)
    bodyLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: AppColors.light2OnBackground,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: AppColors.light2OnBackground,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w400,
      color: AppColors.light2OnBackground,
    ),

    // Labels & Buttons (Nunito)
    labelLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
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
      color: AppColors.light2Background,
    ),
  ),

  colorScheme: const ColorScheme.light(
    primary: AppColors.light2Primary,
    secondary: AppColors.light2Secondary,
    surface: AppColors.light2Surface,
    onPrimary: Colors.white,
    onSurface: AppColors.light2OnBackground,
    error: AppColors.light2Error,
  ),

  extensions: [
    const BackgroundImageTheme(imagePath: 'assets/img/themes/theme_2.jpg'),
  ],
);

// ----- LIGHT THEME 3: Green/Coral (Fresh) -----
final ThemeData lightTheme3 = ThemeData.light().copyWith(
  primaryColor: AppColors.light3Primary,
  scaffoldBackgroundColor: AppColors.light3Background,

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.light3Primary,
    foregroundColor: Colors.white,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.light3Primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.white,
    ),
  ),

  textTheme: const TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w700,
      color: AppColors.light3OnBackground,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light3OnBackground,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light3OnBackground,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light3OnBackground,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light3OnBackground,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light3OnBackground,
    ),

    // Titles
    titleLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light3OnBackground,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light3OnBackground,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w400,
      color: AppColors.light3OnBackground,
    ),

    // Body (Nunito)
    bodyLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: AppColors.light3OnBackground,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: AppColors.light3OnBackground,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w400,
      color: AppColors.light3OnBackground,
    ),

    // Labels & Buttons (Nunito)
    labelLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
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
      color: AppColors.light3Background,
    ),
  ),

  colorScheme: const ColorScheme.light(
    primary: AppColors.light3Primary,
    secondary: AppColors.light3Secondary,
    surface: AppColors.light3Surface,
    onPrimary: Colors.white,
    onSurface: AppColors.light3OnBackground,
    error: AppColors.light3Error,
  ),

  extensions: [
    const BackgroundImageTheme(imagePath: 'assets/img/themes/theme_3.png'),
  ],
);
// ----- LIGHT THEME 4: Orange (Vibrant) -----
final ThemeData lightTheme4 = ThemeData.light().copyWith(
  primaryColor: AppColors.light4Primary,
  scaffoldBackgroundColor: AppColors.light4Background,

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.light4Primary,
    foregroundColor: Colors.white,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.light4Primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.white,
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w700,
      color: AppColors.light4OnBackground,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light4OnBackground,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light4OnBackground,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.light4OnBackground,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light4OnBackground,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light4OnBackground,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light4OnBackground,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.light4OnBackground,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w400,
      color: AppColors.light4OnBackground,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: AppColors.light4OnBackground,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: AppColors.light4OnBackground,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w400,
      color: AppColors.light4OnBackground,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
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
      color: AppColors.light4Background,
    ),
  ),

  colorScheme: const ColorScheme.light(
    primary: AppColors.light4Primary,
    secondary: AppColors.light4Secondary,
    surface: AppColors.light4Surface,
    onPrimary: Colors.white,
    onSurface: AppColors.light4OnBackground,
    error: AppColors.light4Error,
  ),

  extensions: [
    const BackgroundImageTheme(imagePath: 'assets/img/themes/theme_7.png'),
  ],
);

// ----- DARK THEME 1: Deep Purple/Amber (Rich) -----
final ThemeData darkTheme1 = ThemeData.dark().copyWith(
  primaryColor: AppColors.dark1Primary,
  scaffoldBackgroundColor: AppColors.dark1Background,

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.dark1Primary,
    foregroundColor: Colors.white,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.dark1Surface,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.white,
    ),
  ),

  textTheme: const TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w700,
      color: AppColors.dark1OnBackground,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.dark1OnBackground,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.dark1OnBackground,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.dark1OnBackground,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark1OnBackground,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark1OnBackground,
    ),

    // Titles
    titleLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark1OnBackground,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark1OnBackground,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w400,
      color: AppColors.dark1OnBackground,
    ),

    // Body (Nunito)
    bodyLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: AppColors.dark1OnBackground,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: AppColors.dark1OnBackground,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w400,
      color: AppColors.dark1OnBackground,
    ),

    // Labels & Buttons (Nunito)
    labelLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
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
      color: AppColors.dark1Background,
    ),
  ),

  colorScheme: const ColorScheme.dark(
    primary: AppColors.dark1Primary,
    secondary: AppColors.dark1Secondary,
    surface: AppColors.dark1Surface,
    onPrimary: Colors.white,
    onSurface: AppColors.dark1OnBackground,
    error: AppColors.dark1Error,
  ),

  extensions: [
    const BackgroundImageTheme(imagePath: 'assets/img/themes/theme_4.jpg'),
  ],
);

// ----- DARK THEME 2: Blue/Grey (Professional) -----
final ThemeData darkTheme2 = ThemeData.dark().copyWith(
  primaryColor: AppColors.dark2Primary,
  scaffoldBackgroundColor: AppColors.dark2Background,

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.dark2Primary,
    foregroundColor: Colors.white,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.dark2Surface,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.white,
    ),
  ),

  textTheme: const TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w700,
      color: AppColors.dark2OnBackground,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.dark2OnBackground,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.dark2OnBackground,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.dark2OnBackground,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark2OnBackground,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark2OnBackground,
    ),

    // Titles
    titleLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark2OnBackground,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark2OnBackground,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w400,
      color: AppColors.dark2OnBackground,
    ),

    // Body (Nunito)
    bodyLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: AppColors.dark2OnBackground,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: AppColors.dark2OnBackground,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w400,
      color: AppColors.dark2OnBackground,
    ),

    // Labels & Buttons (Nunito)
    labelLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
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
      color: AppColors.dark2Background,
    ),
  ),

  colorScheme: const ColorScheme.dark(
    primary: AppColors.dark2Primary,
    secondary: AppColors.dark2Secondary,
    surface: AppColors.dark2Surface,
    onPrimary: Colors.white,
    onSurface: AppColors.dark2OnBackground,
    error: AppColors.dark2Error,
  ),

  extensions: [
    const BackgroundImageTheme(imagePath: 'assets/img/themes/theme_5.jpg'),
  ],
);

// ----- DARK THEME 3: Forest Green/Amber (Nature) -----
final ThemeData darkTheme3 = ThemeData.dark().copyWith(
  primaryColor: AppColors.dark3Primary,
  scaffoldBackgroundColor: AppColors.dark3Background,

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.dark3Primary,
    foregroundColor: Colors.white,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.dark3Surface,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.white,
    ),
  ),

  textTheme: const TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w700,
      color: AppColors.dark3OnBackground,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.dark3OnBackground,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.dark3OnBackground,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      color: AppColors.dark3OnBackground,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark3OnBackground,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark3OnBackground,
    ),

    // Titles
    titleLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark3OnBackground,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w500,
      color: AppColors.dark3OnBackground,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w400,
      color: AppColors.dark3OnBackground,
    ),

    // Body (Nunito)
    bodyLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: AppColors.dark3OnBackground,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: AppColors.dark3OnBackground,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w400,
      color: AppColors.dark3OnBackground,
    ),

    // Labels & Buttons (Nunito)
    labelLarge: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
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
      color: AppColors.dark3Background,
    ),
  ),

  colorScheme: const ColorScheme.dark(
    primary: AppColors.dark3Primary,
    secondary: AppColors.dark3Secondary,
    surface: AppColors.dark3Surface,
    onPrimary: Colors.white,
    onSurface: AppColors.dark3OnBackground,
    error: AppColors.dark3Error,
  ),

  extensions: [
    const BackgroundImageTheme(imagePath: 'assets/img/themes/theme_6.jpg'),
  ],
);
final List<ThemeData> allThemes = [
  lightTheme1, // 0 - Purple/Teal (Light)
  lightTheme2, // 1 - Blue/Orange (Light)
  lightTheme3, // 2 - Green/Coral (Light)
  lightTheme4, // 3 - Orange/Purple (Light)
  darkTheme1,  // 4 - Deep Purple/Amber (Dark)
  darkTheme2,  // 5 - Blue/Grey (Dark)
  darkTheme3,  // 6 - Forest Green/Amber (Dark)
];