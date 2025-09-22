import 'dart:convert';
import 'dart:developer';
import 'package:consist/features/habit/domain/create_habit/entities/analytics_models.dart';
import 'package:consist/features/habit/domain/create_habit/entities/habit_model.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HabitDatabase {
  static final HabitDatabase instance = HabitDatabase._init();
  static Database? _database;

  HabitDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habits.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE habits (
          id TEXT PRIMARY KEY,
          habitName TEXT,
          goalValue TEXT,
          goalCount TEXT,
          goalCompletedCount TEXT,
          habitIconId TEXT,
          category TEXT,
          habitType TEXT,
          habitStartAt TEXT,
          habitTime TEXT,
          habitEndAt TEXT,
          habitRepeatValue TEXT,
          repeatDays TEXT,
          habitRemindTime TEXT,
          habitColorId TEXT,
          isCompleteToday TEXT,
          note TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE habit_analytics (
          habitId TEXT PRIMARY KEY,
          createdAt TEXT,           
          streakStartedAt TEXT,     
          lastDay TEXT,
          currentStreak TEXT,
          bestStreak TEXT,
          mostActiveDays TEXT,
          completionRate TEXT,
          weeklyCompletionRate TEXT,
          monthlyCompletionRate TEXT,
          yearlyCompletionRate TEXT,
          starsEarned TEXT,
          achievements TEXT,
          FOREIGN KEY (habitId) REFERENCES habits(id) ON DELETE CASCADE
        );
      ''');
      await db.execute('''
  CREATE TABLE habit_completions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  habitId TEXT,
  completionDate TEXT,
  isCompleted INTEGER,
  FOREIGN KEY (habitId) REFERENCES habits(id) ON DELETE CASCADE
);
''');
    } catch (e) {
      log("Error creating tables: $e");
    }
  }

  // ✅ Create
  Future<int> createHabit(Habit habit) async {
    try {
      final db = await instance.database;
      return await db
          .insert('habits', {
            'id': habit.id,
            'habitName': habit.habitName,
            'note': habit.note,
            'habitIconId': habit.habitIconId,
            'category': habit.category,
            'habitStartAt': habit.habitStartAt,
            'habitTime': habit.habitTime,
            'habitEndAt': habit.habitEndAt,
            'habitRepeatValue': habit.habitRepeatValue,
            'repeatDays': habit.repeatDays,
            'habitRemindTime': habit.habitRemindTime,
            'habitColorId': habit.habitColorId,
            'isCompleteToday': habit.isCompleteToday,
            'goalValue': habit.goalValue,
            'goalCount': habit.goalCount,
            'goalCompletedCount': habit.goalCompletedCount,
          })
          .then(
            (value) async => await db.insert('habit_analytics', {
              'habitId': habit.id,
              'createdAt': DateTime.now().toString(),
              'streakStartedAt': '',
              'currentStreak': '0',
              'bestStreak': '0',
              'mostActiveDays': jsonEncode(<int>[]),
              'completionRate': '0.0',
              'weeklyCompletionRate': '0.0',
              'monthlyCompletionRate': '0.0',
              'yearlyCompletionRate': '0.0',
              'starsEarned': '0',
              'lastDay': '',
              'achievements': jsonEncode(<int>[]),
            }, conflictAlgorithm: ConflictAlgorithm.replace),
          );
    } catch (e) {
      log("Error creating habit: $e");
      return -1;
    }
  }

  // ✅ Read all
  Future<List<Habit>> getAllHabits() async {
    try {
      final db = await instance.database;
      final result = await db.query('habits');

      return result
          .map(
            (map) => Habit(
              id: map['id'] as String,
              habitName: map['habitName'] as String?,
              note: map['note'] as String?,
              habitIconId: map['habitIconId'] as String?,
              category: map['category'] as String?,
              habitStartAt: map['habitStartAt'] as String?,
              habitTime: map['habitTime'] as String?,
              habitEndAt: map['habitEndAt'] as String?,
              habitRepeatValue: map['habitRepeatValue'] as String?,
              repeatDays: map['repeatDays'] as String?,
              habitRemindTime: map['habitRemindTime'] as String?,
              habitColorId: map['habitColorId'] as String?,
              isCompleteToday: map['isCompleteToday'] as String?,
              goalValue: map['goalValue'] as String?,
              goalCount: map['goalCount'] as String?,
              goalCompletedCount: map['goalCompletedCount'] as String?,
            ),
          )
          .toList();
    } catch (e) {
      log("Error getting all habits: $e");
      return [];
    }
  }

  // ✅ Read one by ID
  Future<Habit?> getHabitById(String id) async {
    try {
      final db = await instance.database;
      final result = await db.query('habits', where: 'id = ?', whereArgs: [id]);
      if (result.isNotEmpty) {
        final map = result.first;
        return Habit(
          id: map['id'] as String,
          habitName: map['habitName'] as String?,
          note: map['note'] as String?,
          habitIconId: map['habitIconId'] as String?,
          habitStartAt: map['habitStartAt'] as String?,
          category: map['category'] as String?,
          habitTime: map['habitTime'] as String?,
          habitEndAt: map['habitEndAt'] as String?,
          habitRepeatValue: map['habitRepeatValue'] as String?,
          repeatDays: map['repeatDays'] as String?,
          habitRemindTime: map['habitRemindTime'] as String?,
          habitColorId: map['habitColorId'] as String?,
          isCompleteToday: map['isCompleteToday'] as String?,
          goalValue: map['goalValue'] as String?,
          goalCount: map['goalCount'] as String?,
          goalCompletedCount: map['goalCompletedCount'] as String?,
        );
      }
      return null;
    } catch (e) {
      log("Error getting habit by ID: $e");
      return null;
    }
  }

  Future<int> resetHabitsIfNewDay() async {
    try {
      final db = await instance.database;

      // Get today's date in DD:MM:YYYY format
      final today = DateTime.now();
      final todayStr = "${today.day}:${today.month}:${today.year}";

      // Query all habits
      final habits = await db.query('habits');

      for (var habit in habits) {
        final lastCompleteDate = habit['isCompleteToday'] as String?;

        // If lastCompleteDate != today, reset
        if (lastCompleteDate != todayStr) {
          await db.update(
            'habits',
            {
              'isCompleteToday': null, 
              'goalCompletedCount': '0', 
            },
            where: 'id = ?',
            whereArgs: [habit['id']],
          );
        }
      }

      log("Habits reset check done for $todayStr ✅");
      return 1;
    } catch (e) {
      log("Error resetting habits: $e");
      return -1;
    }
  }

  // ✅ Reset goal completed count

  Future<int> resetGoalCompletedCount(String habitId) async {
    try {
      final db = await instance.database;
      return await db.update(
        'habits',
        {'goalCompletedCount': '0'},
        where: 'id = ?',
        whereArgs: [habitId],
      );
    } catch (e) {
      log("Error resetting goal completed count: $e");
      return -1;
    }
  }

  Future<int> getHabitCompletionCount(String habitId) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'habits',
        columns: ['goalCompletedCount'],
        where: 'id = ?',
        whereArgs: [habitId],
      );
      if (result.isNotEmpty) {
        final countStr = result.first['goalCompletedCount'] as String?;
        return int.tryParse(countStr ?? '0') ?? 0;
      }
      return 0;
    } catch (e) {
      log("Error getting habit completion count: $e");
      return 0;
    }
  }

  // ✅ Update habit completion count
  Future<int> updateHabitCompletionCount(String habitId) async {
    try {
      final db = await instance.database;
      int currentCount = await getHabitCompletionCount(habitId);
      currentCount += 1;
      return await db.update(
        'habits',
        {'goalCompletedCount': currentCount.toString()},
        where: 'id = ?',
        whereArgs: [habitId],
      );
    } catch (e) {
      log("Error updating habit completion count: $e");
      return -1;
    }
  }

  // ✅ Update
  Future<int> updateHabit(Habit habit) async {
    try {
      final db = await instance.database;
      return await db.update(
        'habits',
        {
          'habitName': habit.habitName,
          'note': habit.note,
          'habitIconId': habit.habitIconId,
          'category': habit.category,
          'habitStartAt': habit.habitStartAt,
          'habitTime': habit.habitTime,
          'habitEndAt': habit.habitEndAt,
          'habitRepeatValue': habit.habitRepeatValue,
          'repeatDays': habit.repeatDays,
          'habitRemindTime': habit.habitRemindTime,
          'habitColorId': habit.habitColorId,
          'isCompleteToday': habit.isCompleteToday,
          'goalValue': habit.goalValue,
          'goalCount': habit.goalCount,
          'goalCompletedCount': habit.goalCompletedCount,
        },
        where: 'id = ?',
        whereArgs: [habit.id],
      );
    } catch (e) {
      log("Error updating habit: $e");
      return -1;
    }
  }

  // ✅ Delete
  Future<int> deleteHabit(String id) async {
    try {
      final db = await instance.database;
      return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      log("Error deleting habit: $e");
      return -1;
    }
  }

  // ✅ Close DB
  Future close() async {
    try {
      final db = await instance.database;
      await db.close();
    } catch (e) {
      log("Error closing database: $e");
    }
  }

  Future<int> getTargetCompletionCount(String habitId) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'habits',
        columns: ['goalCount'],
        where: 'id = ?',
        whereArgs: [habitId],
      );
      if (result.isNotEmpty) {
        final countStr = result.first['goalCount'] as String?;
        return int.tryParse(countStr ?? '0') ?? 0;
      }
      return 0;
    } catch (e) {
      log("Error getting target completion count: $e");
      return 0;
    }
  }

  Future<void> markHabitComplete({
    required String habitId,
    required String completionDate, // Format: 'YYYY-MM-DD'
    required HabitAnalytics analytics,
    required bool isCompleted,
  }) async {
    try {
      final db = await instance.database;
      final targetCount = await getTargetCompletionCount(habitId);
      await db.update(
        'habits',
        {
          'isCompleteToday': completionDate,
          'goalCompletedCount': targetCount.toString(),
        },
        where: 'id = ?',
        whereArgs: [habitId],
      );
      // 1️⃣ Insert (or update) completion event for this habit & date.
      final formattedDate = normalizeDateString(completionDate);
      await db.insert('habit_completions', {
        'habitId': habitId,
        'completionDate': formattedDate,
        'isCompleted': isCompleted ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 3️⃣ Recalculate the weekly completion rate using actual completion data
      double weeklyCompletionRate = await calculateWeeklyCompletionRate(
        habitId,
      );
      double monthlyCompletionRate = await calculateMonthlyCompletionRate(
        habitId,
      );
      double yearlyCompletionRate = await calculateYearlyCompletionRate(
        habitId,
      );

      // 4️⃣ Update analytics (after recalculating)
      await db.update(
        'habit_analytics',
        {
          'currentStreak': analytics.currentStreak.toString(),
          'bestStreak': analytics.bestStreak.toString(),
          'mostActiveDays': jsonEncode(analytics.mostActiveDays),
          'completionRate': analytics.completionRate.toString(),
          'weeklyCompletionRate': weeklyCompletionRate.toString(),
          'monthlyCompletionRate': monthlyCompletionRate.toString(),
          'yearlyCompletionRate': yearlyCompletionRate.toString(),
          'starsEarned': analytics.starsEarned.toString(),
          'lastDay': analytics.lastDay,
          'achievements': jsonEncode(analytics.achievements),
          'streakStartedAt': analytics.streakStartedAt,
        },
        where: 'habitId = ?',
        whereArgs: [habitId],
      );
    } catch (e) {
      log("Error marking habit complete: $e");
    }
  }

  Future<double> calculateWeeklyCompletionRate(String habitId) async {
    final db = await instance.database;
    final today = DateTime.now();
    final weekAgo = today.subtract(Duration(days: 6));
    final maps = await db.query(
      'habit_completions',
      where: 'habitId = ? AND completionDate BETWEEN ? AND ?',
      whereArgs: [
        habitId,
        weekAgo.toIso8601String().substring(0, 10),
        today.toIso8601String().substring(0, 10),
      ],
    );
    if (maps.isEmpty) return 0.0;
    int completed = maps.where((m) => m['isCompleted'] == 1).length;
    int totalDays = 7; // Or count days with expected completions
    return (completed / totalDays) * 100.0;
  }

  Future<double> calculateMonthlyCompletionRate(String habitId) async {
    final db = await instance.database;
    final today = DateTime.now();
    final beginningOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(
      today.year,
      today.month + 1,
      0,
    ); // Last day of current month

    final maps = await db.query(
      'habit_completions',
      where: 'habitId = ? AND completionDate BETWEEN ? AND ?',
      whereArgs: [
        habitId,
        beginningOfMonth.toIso8601String().substring(0, 10),
        endOfMonth.toIso8601String().substring(0, 10),
      ],
    );
    if (maps.isEmpty) return 0.0;
    int completed = maps.where((m) => m['isCompleted'] == 1).length;
    int totalDays = endOfMonth.day; // Number of days in the month
    return (completed / totalDays) * 100.0;
  }

  Future<double> calculateYearlyCompletionRate(String habitId) async {
    final db = await instance.database;
    final today = DateTime.now();
    final beginningOfYear = DateTime(today.year, 1, 1);
    final endOfYear = DateTime(today.year, 12, 31);

    final maps = await db.query(
      'habit_completions',
      where: 'habitId = ? AND completionDate BETWEEN ? AND ?',
      whereArgs: [
        habitId,
        beginningOfYear.toIso8601String().substring(0, 10),
        endOfYear.toIso8601String().substring(0, 10),
      ],
    );
    if (maps.isEmpty) return 0.0;
    int completed = maps.where((m) => m['isCompleted'] == 1).length;
    int totalDays = 365; // Not accounting for leap years for simplicity
    return (completed / totalDays) * 100.0;
  }

  // ✅ Get habits by category
  Future<List<Habit>> getHabitsByCategory(String category) async {
    try {
      final db = await instance.database;

      final result = await db.query(
        'habits',
        where: 'category = ?',
        whereArgs: [category],
      );

      if (result.isEmpty) return [];

      return result.map((map) {
        return Habit(
          id: map['id']?.toString() ?? "",
          habitName: map['habitName'] as String?,
          note: map['note'] as String?,
          habitIconId: map['habitIconId'] as String?,
          category: map['category'] as String?,
          habitStartAt: map['habitStartAt'] as String?,
          habitTime: map['habitTime'] as String?,
          habitEndAt: map['habitEndAt'] as String?,
          habitRepeatValue: map['habitRepeatValue'] as String?,
          repeatDays: map['repeatDays'] as String?,
          habitRemindTime: map['habitRemindTime'] as String?,
          habitColorId: map['habitColorId'] as String?,
          isCompleteToday: map['isCompleteToday'] as String?,
          goalValue: map['goalValue'] as String?,
          goalCount: map['goalCount'] as String?,
          goalCompletedCount: map['goalCompletedCount'] as String?,
        );
      }).toList();
    } catch (e, st) {
      log("Error getting habits by category: $e\n$st");
      return [];
    }
  }

  // ✅ Get habit analytics
  Future<HabitAnalytics?> getHabitAnalytics(String habitId) async {
    try {
      final db = await instance.database;

      final maps = await db.query(
        'habit_analytics',
        where: 'habitId = ?',
        whereArgs: [habitId],
      );

      if (maps.isNotEmpty) {
        return HabitAnalytics.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      log("Error fetching habit analytics: $e");
      return null;
    }
  }

  // ✅ calculate and update analytics

  Future<HabitAnalytics?> calculateUpdatedAnalytics(String habitId) async {
    try {
      final db = await instance.database;

      final maps = await db.query(
        'habit_analytics',
        where: 'habitId = ?',
        whereArgs: [habitId],
      );

      if (maps.isEmpty) return null;

      final current = HabitAnalytics.fromMap(maps.first);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      DateTime? lastDay;
      if (current.lastDay.isNotEmpty) {
        lastDay = DateTime.tryParse(current.lastDay);
      }

      int currentStreak = current.currentStreak;
      int bestStreak = current.bestStreak;
      String streakStartedAt = current.streakStartedAt;

      // 🔹 Streak logic
      if (lastDay == null) {
        // First ever completion
        currentStreak = 1;
        streakStartedAt = today.toIso8601String();
      } else {
        final diff = today
            .difference(DateTime(lastDay.year, lastDay.month, lastDay.day))
            .inDays;

        if (diff == 0) {
          // Already completed today → no update
          return current;
        } else if (diff == 1) {
          currentStreak += 1;
        } else {
          // streak broken, start over
          currentStreak = 1;
          streakStartedAt = today.toIso8601String();
        }
      }

      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
      }

      // 🔹 Most active days
      List<int> mostActiveDays = List.from(current.mostActiveDays);
      mostActiveDays.add(today.weekday);

      // 🔹 Increment completion rates (simplistic)
      double completionRate = current.completionRate + 1;
      double weekly = current.weeklyCompletionRate + 1;
      double monthly = current.monthlyCompletionRate + 1;
      double yearly = current.yearlyCompletionRate + 1;

      final updated = current.copyWith(
        lastDay: today.toIso8601String(),
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        mostActiveDays: mostActiveDays,
        completionRate: completionRate,
        weeklyCompletionRate: weekly,
        monthlyCompletionRate: monthly,
        yearlyCompletionRate: yearly,
        streakStartedAt: streakStartedAt,
      );

      // 🔹 Persist back to DB
      await db.update(
        'habit_analytics',
        updated.toMap(),
        where: 'habitId = ?',
        whereArgs: [habitId],
      );

      return updated;
    } catch (e) {
      log("Error calculating updated analytics: $e");
      return null;
    }
  }

  // update streak

  Future<HabitAnalytics?> checkStreakAndFetchAnalytics(String habitId) async {
    try {
      final db = await HabitDatabase.instance.database;

      final analyticsMap = await db.query(
        'habit_analytics',
        where: 'habitId = ?',
        whereArgs: [habitId],
      );

      if (analyticsMap.isEmpty) return null;

      final analytics = HabitAnalytics.fromMap(analyticsMap.first);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      DateTime? lastDay;
      if (analytics.lastDay.isNotEmpty) {
        lastDay = DateTime.tryParse(analytics.lastDay);
      }

      int currentStreak = analytics.currentStreak;
      String streakStartedAt = analytics.streakStartedAt;

      if (lastDay == null) {
        // No last day recorded → no streak yet

        return analytics;
      }

      final diff = today
          .difference(DateTime(lastDay.year, lastDay.month, lastDay.day))
          .inDays;

      if (diff == 0) {
        // Already completed today → streak intact
        return analytics;
      } else if (diff == 1) {
        // Yesterday completed, today not yet → streak still valid
        return analytics;
      } else if (diff > 1) {
        // User missed at least one day → streak broken
        currentStreak = 0;
        streakStartedAt = ''; // Clear or reset
      }

      final updatedAnalytics = analytics.copyWith(
        currentStreak: currentStreak,
        streakStartedAt: streakStartedAt,
      );

      await db.update(
        'habit_analytics',
        {
          'currentStreak': updatedAnalytics.currentStreak.toString(),
          'streakStartedAt': updatedAnalytics.streakStartedAt,
        },
        where: 'habitId = ?',
        whereArgs: [habitId],
      );

      return updatedAnalytics;
    } catch (e, st) {
      log("Error checking/updating streak: $e\n$st");
      return null;
    }
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'habits.db');

    try {
      await deleteDatabase(path);
      log("✅ Database deleted successfully");
    } catch (e) {
      log("❌ Error deleting database: $e");
    }
  }

  String normalizeDateString(String date) {
    // Replace colons with slashes or whatever matches your format, then parse
    final parts = date.split(':'); // ['11', '9', '2025']
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    final dateTime = DateTime(year, month, day);
    // Format to ISO 8601
    final formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
    return formattedDate;
  }
}
