import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

class AppTheme {
  static ThemeData get light => lightTheme;
  static ThemeData get dark => darkTheme;
}
// import 'package:flutter/material.dart';

// class AppTheme {
//   // ---------- LIGHT COLORS ----------
//   static const Color lightPrimary = Color(0xFF3F51B5);
//   static const Color lightSecondary = Color(0xFF7986CB);
//   static const Color lightBackground = Color(0xFFF5F5F5);
//   static const Color lightSurface = Color(0xFFFFFFFF);
//   static const Color lightOnBackground = Color(0xFF212121);

//   // ---------- DARK COLORS ----------
//   static const Color darkPrimary = Color(0xFF303F9F);
//   static const Color darkSecondary = Color(0xFF03DAC6);
//   static const Color darkBackground = Color(0xFF121212);
//   static const Color darkSurface = Color(0xFF1E1E1E);
//   static const Color darkOnBackground = Color(0xFFE0E0E0);
//   static const Color darkOnSurface = Color(0xFFCCCCCC);

//   // ================= LIGHT THEME =================
//   static final ThemeData lightTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.light,
//     scaffoldBackgroundColor: lightBackground,
//     fontFamily: 'Quicksand',
//     colorScheme: const ColorScheme.light(
//       primary: lightPrimary,
//       secondary: lightSecondary,
//       surface: lightSurface,
//       onSurface: lightOnBackground,
//       primaryContainer: Color(0xFFE8EAF6),
//       outline: Color(0xFFBDBDBD),
//     ),
//     inputDecorationTheme: const InputDecorationTheme(
//       border: InputBorder.none,
//     ),
//     appBarTheme: const AppBarTheme(
//       elevation: 0,
//       scrolledUnderElevation: 0,
//     ),
//   );

//   // ================= DARK THEME =================
//   static final ThemeData darkTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.dark,
//     scaffoldBackgroundColor: darkBackground,
//     fontFamily: 'Quicksand',
//     colorScheme: const ColorScheme.dark(
//       primary: darkPrimary,
//       secondary: darkSecondary,
//       surface: darkSurface,
//       onSurface: darkOnSurface,
//       primaryContainer: Color(0xFF3949AB),
//       outline: Color(0xFF424242),
//     ),
//     inputDecorationTheme: const InputDecorationTheme(
//       border: InputBorder.none,
//     ),
//     appBarTheme: const AppBarTheme(
//       elevation: 0,
//       scrolledUnderElevation: 0,
//     ),
//   );
// }
