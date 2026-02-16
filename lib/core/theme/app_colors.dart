import 'package:flutter/material.dart';

class AppColors {
    // ---------- LIGHT COLORS ----------
  static const Color lightPrimary = Color(0xFF3F51B5);
  static const Color lightSecondary = Color(0xFF7986CB);
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF212121);

  // ---------- DARK COLORS ----------
  static const Color darkPrimary = Color(0xFF303F9F);
  static const Color darkSecondary = Color(0xFF03DAC6);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnBackground = Color(0xFFE0E0E0);
  static const Color darkOnSurface = Color(0xFFCCCCCC);

  static final List<Map<String, dynamic>> lightColors = [
    {"id": 0, "color": Colors.red[200]!},
    {"id": 1, "color": Colors.pink[200]!},
    {"id": 2, "color": Colors.purple[200]!},
    {"id": 3, "color": Colors.deepPurple[200]!},
    {"id": 4, "color": Colors.indigo[200]!},
    {"id": 5, "color": Colors.blue[200]!},
    {"id": 6, "color": Colors.lightBlue[200]!},
    {"id": 7, "color": Colors.cyan[200]!},
    {"id": 8, "color": Colors.teal[200]!},
    {"id": 9, "color": Colors.green[200]!},
    {"id": 10, "color": Colors.lightGreen[200]!},
    {"id": 11, "color": Colors.lime[200]!},
    {"id": 12, "color": Colors.yellow[200]!},
    {"id": 13, "color": Colors.amber[200]!},
    {"id": 14, "color": Colors.orange[200]!},
    {"id": 15, "color": Colors.deepOrange[200]!},
    {"id": 16, "color": Colors.brown[200]!},
  ];

  static final List<Map<String, dynamic>> darkColors = [
    {"id": 0, "color": Colors.red[700]!},
    {"id": 1, "color": Colors.pink[700]!},
    {"id": 2, "color": Colors.purple[700]!},
    {"id": 3, "color": Colors.deepPurple[700]!},
    {"id": 4, "color": Colors.indigo[700]!},
    {"id": 5, "color": Colors.blue[700]!},
    {"id": 6, "color": Colors.lightBlue[700]!},
    {"id": 7, "color": Colors.cyan[700]!},
    {"id": 8, "color": Colors.teal[700]!},
    {"id": 9, "color": Colors.green[700]!},
    {"id": 10, "color": Colors.lightGreen[700]!},
    {"id": 11, "color": Colors.lime[700]!},
    {"id": 12, "color": Colors.yellow[700]!},
    {"id": 13, "color": Colors.amber[700]!},
    {"id": 14, "color": Colors.orange[700]!},
    {"id": 15, "color": Colors.deepOrange[700]!},
    {"id": 16, "color": Colors.brown[700]!},
  ];
  static final List<Map<String, dynamic>> extraLightColors = [
    {"id": 0, "color": Colors.red.withValues(alpha: 0.1)},
    {"id": 1, "color": Colors.pink.withValues(alpha: 0.1)},
    {"id": 2, "color": Colors.purple.withValues(alpha: 0.1)},
    {"id": 3, "color": Colors.deepPurple.withValues(alpha: 0.1)},
    {"id": 4, "color": Colors.indigo.withValues(alpha: 0.1)},
    {"id": 5, "color": Colors.blue.withValues(alpha: 0.1)},
    {"id": 6, "color": Colors.lightBlue.withValues(alpha: 0.1)},
    {"id": 7, "color": Colors.cyan.withValues(alpha: 0.1)},
    {"id": 8, "color": Colors.teal.withValues(alpha: 0.1)},
    {"id": 9, "color": Colors.green.withValues(alpha: 0.1)},
    {"id": 10, "color": Colors.lightGreen.withValues(alpha: 0.1)},
    {"id": 11, "color": Colors.lime.withValues(alpha: 0.1)},
    {"id": 12, "color": Colors.yellow.withValues(alpha: 0.1)},
    {"id": 13, "color": Colors.amber.withValues(alpha: 0.1)},
    {"id": 14, "color": Colors.orange.withValues(alpha: 0.1)},
    {"id": 15, "color": Colors.deepOrange.withValues(alpha: 0.1)},
    {"id": 16, "color": Colors.brown.withValues(alpha: 0.1)},
  ];
}
