import 'dart:math';

import 'package:consist/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CommonFunctions {
  static int getRandomNumber(int min, int max) {
    final random = Random();
    return min + random.nextInt(max - min + 1);
  }

  static TimeOfDay parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Get color by ID from both light and dark color lists
  static Color? getColorById(String id) {
    // Combine both light and dark color lists
    final allColors = [...AppColors.lightColors, ...AppColors.darkColors];
    
    try {
      final match = allColors.firstWhere(
        (map) => map['id'].toString() == id, // Convert id to string for comparison
        orElse: () => {},
      );
      
      if (match.isNotEmpty && match.containsKey('color')) {
        return match['color'] as Color?;
      }
    } catch (e) {
      debugPrint('Error getting color by id $id: $e');
    }
    
    return null;
  }

  /// Get light color by ID
  static Color? getLightColorById(String id) {
    try {
      final match = AppColors.lightColors.firstWhere(
        (map) => map['id'].toString() == id,
        orElse: () => {},
      );
      
      if (match.isNotEmpty && match.containsKey('color')) {
        return match['color'] as Color?;
      }
    } catch (e) {
      debugPrint('Error getting light color by id $id: $e');
    }
    
    return null;
  }

  /// Get dark color by ID
  static Color? getDarkColorById(String id) {
    try {
      final match = AppColors.darkColors.firstWhere(
        (map) => map['id'].toString() == id,
        orElse: () => {},
      );
      
      if (match.isNotEmpty && match.containsKey('color')) {
        return match['color'] as Color?;
      }
    } catch (e) {
      debugPrint('Error getting dark color by id $id: $e');
    }
    
    return null;
  }

  /// Get color by ID based on theme brightness
  static Color? getThemeAwareColorById(String id, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.darkColors : AppColors.lightColors;
    
    try {
      final match = colors.firstWhere(
        (map) => map['id'].toString() == id,
        orElse: () => {},
      );
      
      if (match.isNotEmpty && match.containsKey('color')) {
        return match['color'] as Color?;
      }
    } catch (e) {
      debugPrint('Error getting theme aware color by id $id: $e');
    }
    
    return null;
  }

  /// Get extra light color by ID (transparent version)
  static Color? getExtraLightColorById(String id) {
    try {
      final match = AppColors.extraLightColors.firstWhere(
        (map) => map['id'].toString() == id,
        orElse: () => {},
      );
      
      if (match.isNotEmpty && match.containsKey('color')) {
        return match['color'] as Color?;
      }
    } catch (e) {
      debugPrint('Error getting extra light color by id $id: $e');
    }
    
    return null;
  }

  /// Darken a color by a given amount
  static Color darken(Color color, [double amount = 0.3]) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Lighten a color by a given amount
  static Color lighten(Color color, [double amount = 0.3]) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  /// Check if a new day has started for habit tracking
  static bool isNewDayForHabit(String? lastCompletionDateStr) {
    if (lastCompletionDateStr == null) return true;
    
    final parts = lastCompletionDateStr.split(':');
    if (parts.length != 3) return true;

    final lastDay = int.tryParse(parts[0]) ?? 0;
    final lastMonth = int.tryParse(parts[1]) ?? 0;
    final lastYear = int.tryParse(parts[2]) ?? 0;

    final today = DateTime.now();

    return !(lastDay == today.day &&
        lastMonth == today.month &&
        lastYear == today.year);
  }

  /// Get difference in days between a given date string and today
  static int getDateDifference(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 0;
    
    try {
      // Parse the incoming string (expected format: dd:MM:yyyy)
      final parts = dateString.split(':');
      if (parts.length != 3) {
        throw const FormatException("Invalid date format, expected dd:MM:yyyy");
      }

      final int day = int.parse(parts[0]);
      final int month = int.parse(parts[1]);
      final int year = int.parse(parts[2]);

      // Create DateTime object from parsed values
      final givenDate = DateTime(year, month, day);

      // Get today's date (without time part)
      final today = DateTime.now();
      final currentDate = DateTime(today.year, today.month, today.day);

      // Difference in days
      return givenDate.difference(currentDate).inDays;
    } catch (e) {
      debugPrint('Error calculating date difference: $e');
      return 0;
    }
  }

  /// Format date to string with custom separator
  static String formatDateToString(DateTime date, [String separator = ':']) {
    return '${date.day.toString().padLeft(2, '0')}$separator'
        '${date.month.toString().padLeft(2, '0')}$separator'
        '${date.year}';
  }

  /// Parse date from string with custom separator
  static DateTime? parseDateFromString(String dateString, [String separator = ':']) {
    try {
      final parts = dateString.split(separator);
      if (parts.length != 3) return null;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      return DateTime(year, month, day);
    } catch (e) {
      debugPrint('Error parsing date from string: $e');
      return null;
    }
  }

  /// Get color brightness (returns true if color is dark)
  static bool isColorDark(Color color) {
    return color.computeLuminance() < 0.5;
  }

  /// Get contrasting text color (black or white) based on background
  static Color getContrastingTextColor(Color backgroundColor) {
    return isColorDark(backgroundColor) ? Colors.white : Colors.black;
  }

  /// Get theme-aware primary color
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// Get theme-aware secondary color
  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  /// Get theme-aware surface color
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Get theme-aware background color
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }
}