import 'package:consist/features/habit/domain/create_habit/entities/analytics_models.dart';
import 'package:consist/features/habit/domain/create_habit/entities/habit_model.dart';

abstract class HabitRepository {
  Future<int> createHabit(Habit habit);
  Future<List<Habit>> getAllHabits();
  Future<Habit?> getHabitById(String id);
  Future<int> updateHabit(Habit habit);
  Future<int> deleteHabit(String id);
  Future<void> markHabitComplete({
    required String habitId,
    required String completionDate,
    required HabitAnalytics analytics,
    required bool isComplete
  });
  Future<List<Habit>> getHabitsByCategory(String category);
  Future<HabitAnalytics?> getHabitAnalytics(String id);
  Future<HabitAnalytics?> updateHabitAnalytics(String id);
  Future<HabitAnalytics?> checkStreakAndFetchAnalytics(String id);
  Future<int> resetHabitsIfNewDay();
  Future<int> incrementHabitGoalCount(String habitId);
  Future<int> decrementHabitGoalCount(String habitId);
  Future<int> resetHabitGoalCount(String habitId);
  Future<int> updateHabitGoalCount(String habitId, int count);
}

