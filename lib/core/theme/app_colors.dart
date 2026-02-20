import 'package:flutter/material.dart';


class AppColors {
  // ----- LIGHT THEME 1: Purple/Teal (Modern) -----
  static const Color light1Primary = Color(0xFF7B1FA2); // Deep Purple 700
  static const Color light1Secondary = Color(0xFF00897B); // Teal 600
  static const Color light1Surface = Color(0xFFFFFFFF); // White
  static const Color light1Background = Color(0xFFF3E5F5); // Deep Purple 50
  static const Color light1OnBackground = Color(0xFF1A1A1A); // Near black
  static const Color light1Error = Color(0xFFD32F2F); // Red 700

  // ----- LIGHT THEME 2: Blue/Orange (Vibrant) -----
  static const Color light2Primary = Color(0xFF1976D2); // Blue 700
  static const Color light2Secondary = Color(0xFFFF6F00); // Amber 900
  static const Color light2Surface = Color(0xFFFFFFFF); // White
  static const Color light2Background = Color(0xFFE3F2FD); // Blue 50
  static const Color light2OnBackground = Color(0xFF1A1A1A); // Near black
  static const Color light2Error = Color(0xFFC62828); // Red 800

  // ----- LIGHT THEME 3: Green/Coral (Fresh) -----
  static const Color light3Primary = Color(0xFF2E7D32); // Green 800
  static const Color light3Secondary = Color(0xFFFF8A65); // Coral/Orange 400
  static const Color light3Surface = Color(0xFFFFFFFF); // White
  static const Color light3Background = Color(0xFFE8F5E9); // Green 50
  static const Color light3OnBackground = Color(0xFF1A1A1A); // Near black
  static const Color light3Error = Color(0xFFC2185B); // Pink 700

  // ----- DARK THEME 1: Deep Purple/Amber (Rich) -----
  static const Color dark1Primary = Color(0xFFB39DDB); // Deep Purple 200
  static const Color dark1Secondary = Color(0xFFFFD54F); // Amber 300
  static const Color dark1Surface = Color(0xFF1E1A2B); // Dark purple-grey
  static const Color dark1Background = Color(0xFF121212); // Near black
  static const Color dark1OnBackground = Color(0xFFF5F5F5); // Off-white
  static const Color dark1Error = Color(0xFFEF9A9A); // Red 200

  // ----- DARK THEME 2: Blue/Grey (Professional) -----
  static const Color dark2Primary = Color(0xFF90CAF9); // Blue 200
  static const Color dark2Secondary = Color(0xFF80CBC4); // Teal 200
  static const Color dark2Surface = Color(0xFF1E2428); // Dark blue-grey
  static const Color dark2Background = Color(0xFF0F1419); // Darker blue-grey
  static const Color dark2OnBackground = Color(0xFFF5F5F5); // Off-white
  static const Color dark2Error = Color(0xFFF48FB1); // Pink 300

  // ----- DARK THEME 3: Forest Green/Amber (Nature) -----
  static const Color dark3Primary = Color(0xFFA5D6A7); // Green 200
  static const Color dark3Secondary = Color(0xFFFFB74D); // Orange 300
  static const Color dark3Surface = Color(0xFF1E2A1E); // Dark green-grey
  static const Color dark3Background = Color(0xFF0F1A0F); // Dark forest
  static const Color dark3OnBackground = Color(0xFFF5F5F5); // Off-white
  static const Color dark3Error = Color(0xFFEF9A9A); // Red 200

  // Color palette collections for dynamic features
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
