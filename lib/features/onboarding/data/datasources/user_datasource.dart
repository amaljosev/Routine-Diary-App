import 'dart:developer';
import 'package:consist/core/database/user_db.dart';
import 'package:consist/features/habit/data/datasources/habit_local_datasource.dart';
import 'package:consist/features/onboarding/domain/entities/user_analytics_model.dart';
import 'package:sqflite/sqflite.dart';

class UserLocalDataSource {
  final UserDatabase _dbProvider = UserDatabase.instance;
  static const table = 'user_analytics';

  // CRUD Operations
  String _generateUserId() {
    final now = DateTime.now();
    return 'user_${now.millisecondsSinceEpoch}';
  }

  // Add this function to set up user with auto-generated ID
  Future<String> setupUser({String? username, String? avatar}) async {
    try {
      final db = await _dbProvider.database;

      // Generate unique user ID
      final userId = _generateUserId();

      // Create new user with generated ID
      final newUser = UserAnalytics(
        userId: userId,
        username: username ?? 'User',
        avatar: avatar ?? '',
        installedDate: DateTime.now().toIso8601String(),
        lastLogin: DateTime.now().toIso8601String(),
        lastCompleted: DateTime.now().toIso8601String(),
      );

      await db.insert(
        table,
        newUser.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return userId;
    } catch (e, st) {
      log('setupUser error: $e', stackTrace: st);
      rethrow;
    }
  }

  // Add this function to check if user needs to be set up
  Future<bool> isUserSetupRequired() async {
    try {
      final db = await _dbProvider.database;
      final users = await db.query(table);
      return users.isEmpty;
    } catch (e, st) {
      log('isUserSetupRequired error: $e', stackTrace: st);
      return true; // Assume setup required if error occurs
    }
  }

  Future<UserAnalytics?> getCurrentUser() async {
    try {
      final db = await _dbProvider.database;
      final maps = await db.query(table, limit: 1);

      if (maps.isNotEmpty) {
        return UserAnalytics.fromMap(maps.first);
      }
      return null;
    } catch (e, st) {
      log('getCurrentUser error: $e', stackTrace: st);
      return null;
    }
  }

  Future<int> updateUser(UserAnalytics user) async {
    try {
      final db = await _dbProvider.database;
      return await db.update(
        table,
        user.toMap(),
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
    } catch (e, st) {
      log('updateUser error: $e', stackTrace: st);
      return 0;
    }
  }

  Future<int> deleteUser() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return 0;

      final db = await _dbProvider.database;
      return await db.delete(
        table,
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
    } catch (e, st) {
      log('deleteUser error: $e', stackTrace: st);
      return 0;
    }
  }

  // Specific methods

  Future<int> updateLastLogin() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return 0;

      final db = await _dbProvider.database;
      final now = DateTime.now().toIso8601String();
      return await db.update(
        table,
        {'lastLogin': now},
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
    } catch (e, st) {
      log('updateLastLogin error: $e', stackTrace: st);
      return 0;
    }
  }

  Future<int> updateStreak() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return 0;

      final db = await _dbProvider.database;
      final newCurrentStreak = user.currentStreak + 1;
      final newBestStreak = newCurrentStreak > user.bestStreak
          ? newCurrentStreak
          : user.bestStreak;

      return await db.update(
        table,
        {
          'currentStreak': newCurrentStreak,
          'bestStreak': newBestStreak,
          'lastCompleted': DateTime.now().toIso8601String(),
        },
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
    } catch (e, st) {
      log('updateStreak error: $e', stackTrace: st);
      return 0;
    }
  }

  Future<int> resetCurrentStreak() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return 0;

      final db = await _dbProvider.database;
      return await db.update(
        table,
        {'currentStreak': 0},
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
    } catch (e, st) {
      log('resetCurrentStreak error: $e', stackTrace: st);
      return 0;
    }
  }

  Future<int> incrementDaysActive() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return 0;

      final db = await _dbProvider.database;
      return await db.update(
        table,
        {'totalDaysActive': user.totalDaysActive + 1},
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
    } catch (e, st) {
      log('incrementDaysActive error: $e', stackTrace: st);
      return 0;
    }
  }

  Future<bool> checkAndUpdateDailyStats() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;

      final now = DateTime.now();
      final lastLogin = DateTime.parse(user.lastLogin);

      // Check if we already processed today's update
      if (_isSameDay(lastLogin, now)) {
        return true; // Already updated today, nothing else to do
      }

      // Always update last login timestamp
      await updateLastLogin();
      // ✅ Reset all habits if new day
      await HabitDatabase.instance.resetHabitsForNewDay();

      // Handle streak and activity logic
      await _handleStreakAndActivity(user, now);

      return true; // ✅ Success
    } catch (e, st) {
      log('checkAndUpdateDailyStats error: $e', stackTrace: st);
      return false; // ❌ Failed
    }
  }

  Future<void> _handleStreakAndActivity(
    UserAnalytics user,
    DateTime now,
  ) async {
    if (user.lastCompleted == '') {
      // First time user, just mark as active today
      await incrementDaysActive();
      return;
    }

    final lastCompleted = DateTime.parse(user.lastCompleted);
    final daysSinceLastCompletion = now.difference(lastCompleted).inDays;

    if (daysSinceLastCompletion == 0) {
      // User already completed today, just ensure days active is updated
      if (!_isSameDay(DateTime.parse(user.lastLogin), now)) {
        await incrementDaysActive();
      }
    } else if (daysSinceLastCompletion == 1) {
      // User completed yesterday, continue streak
      await updateStreak();
      await incrementDaysActive();
    } else if (daysSinceLastCompletion > 1) {
      // User missed one or more days, reset streak but still count as active today
      await resetCurrentStreak();
      await incrementDaysActive();
    }
    // If user hasn't completed today but opened app, we don't update streak yet
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<int> addAchievement(int achievementId) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return 0;

      // Check if achievement already exists
      if (user.achievements.contains(achievementId)) {
        return 0; // Already has this achievement
      }

      final db = await _dbProvider.database;
      final updatedAchievements = [...user.achievements, achievementId];

      return await db.update(
        table,
        {'achievements': UserAnalytics.encodeAchievements(updatedAchievements)},
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
    } catch (e, st) {
      log('addAchievement error: $e', stackTrace: st);
      return 0;
    }
  }

  // Remove achievement by ID
  Future<int> removeAchievement(int achievementId) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return 0;

      final db = await _dbProvider.database;
      final updatedAchievements = user.achievements
          .where((id) => id != achievementId)
          .toList();

      return await db.update(
        table,
        {'achievements': UserAnalytics.encodeAchievements(updatedAchievements)},
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
    } catch (e, st) {
      log('removeAchievement error: $e', stackTrace: st);
      return 0;
    }
  }

  // Check if user has specific achievement
  Future<bool> hasAchievement(int achievementId) async {
    try {
      final user = await getCurrentUser();
      return user?.achievements.contains(achievementId) ?? false;
    } catch (e, st) {
      log('hasAchievement error: $e', stackTrace: st);
      return false;
    }
  }

  // Get all achievement IDs
  Future<List<int>> getUserAchievements() async {
    try {
      final user = await getCurrentUser();
      return user?.achievements ?? [];
    } catch (e, st) {
      log('getUserAchievements error: $e', stackTrace: st);
      return [];
    }
  }

  // Get achievement count
  Future<int> getAchievementCount() async {
    try {
      final user = await getCurrentUser();
      return user?.achievements.length ?? 0;
    } catch (e, st) {
      log('getAchievementCount error: $e', stackTrace: st);
      return 0;
    }
  }

  // Clear all achievements
  Future<int> clearAllAchievements() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return 0;

      final db = await _dbProvider.database;
      return await db.update(
        table,
        {'achievements': UserAnalytics.encodeAchievements([])},
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
    } catch (e, st) {
      log('clearAllAchievements error: $e', stackTrace: st);
      return 0;
    }
  }

  Future<int> addStars(int count) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return 0;

      final db = await _dbProvider.database;
      return await db.update(
        table,
        {'stars': user.stars + count},
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
    } catch (e, st) {
      log('addStars error: $e', stackTrace: st);
      return 0;
    }
  }

  // Get complete user profile data for display
  Future<UserAnalytics?> getUserProfile() async {
    try {
      return await getCurrentUser();
    } catch (e, st) {
      log('getUserProfile error: $e', stackTrace: st);
      return null;
    }
  }

  // Get user stats summary
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final user = await getCurrentUser();
      if (user != null) {
        return {
          'username': user.username,
          'avatar': user.avatar,
          'bestStreak': user.bestStreak,
          'currentStreak': user.currentStreak,
          'totalDaysActive': user.totalDaysActive,
          'achievements': user.achievements,
          'stars': user.stars,
          'lastLogin': user.lastLogin,
          'lastCompleted': user.lastCompleted,
          'installedDate': user.installedDate,
        };
      }
      return {};
    } catch (e, st) {
      log('getUserStats error: $e', stackTrace: st);
      return {};
    }
  }

  // Check if user exists (for onboarding flow)
  Future<bool> userExists() async {
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e, st) {
      log('userExists error: $e', stackTrace: st);
      return false;
    }
  }
}
