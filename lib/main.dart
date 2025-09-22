import 'dart:developer';

import 'package:consist/core/app_theme.dart';
import 'package:consist/features/diary/data/datasources/diary_local_data_source.dart';
import 'package:consist/features/diary/data/repository/diary_repo_implementation.dart';
import 'package:consist/features/diary/domain/repository/diary_repository.dart';
import 'package:consist/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:consist/features/habit/data/datasources/habit_local_datasource.dart';
import 'package:consist/features/habit/data/repositories/habit_repository_impl.dart';
import 'package:consist/features/habit/domain/create_habit/repositories/habit_repository.dart';
import 'package:consist/features/habit/presentation/blocs/habits_bloc/habits_bloc.dart';
import 'package:consist/features/onboarding/data/datasources/user_datasource.dart';
import 'package:consist/features/onboarding/data/repositories/user_repo_impl.dart';
import 'package:consist/features/onboarding/domain/repository/user_repo.dart';
import 'package:consist/features/onboarding/presentation/blocs/user_bloc/user_bloc.dart';
import 'package:consist/features/onboarding/presentation/pages/onboarding/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await resetDatabase();
  final userLocalDataSource = UserLocalDataSource();
  final UserRepository userRepository = UserRepositoryImpl(
    localDataSource: userLocalDataSource,
  );

  final habitLocalDataSource = HabitDatabase.instance;
  final HabitRepository habitRepository = HabitRepositoryImpl(
    db: habitLocalDataSource,
  );

  final diaryLocalDataSource = DiaryLocalDataSource();
  final DiaryRepository diaryRepository = DiaryRepositoryImpl(
    diaryLocalDataSource,
  );

  runApp(
    MyApp(
      habitRepo: habitRepository,
      diaryRepo: diaryRepository,
      userRepo: userRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.habitRepo,
    required this.diaryRepo,
    required this.userRepo,
  });

  final HabitRepository habitRepo;
  final DiaryRepository diaryRepo;
  final UserRepository userRepo;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              UserBloc(userRepository: userRepo, habitRepository: habitRepo),
        ),
        BlocProvider(create: (_) => HabitsBloc(habitRepository: habitRepo)),
        BlocProvider(
          create: (_) =>
              DiaryBloc(repository: diaryRepo)..add(LoadDiaryEntries()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

Future<void> resetDatabase() async {
  final dbPath = await getDatabasesPath();
  final habitPath = join(dbPath, 'habits.db');
  final diaryPath = join(dbPath, 'consist_diary.db');
  final userPath = join(dbPath, 'user.db');

  try {
    await deleteDatabase(habitPath);
    await deleteDatabase(diaryPath);
    await deleteDatabase(userPath);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLogged', false);
    await prefs.setString('userId', '');
    log("✅ Database deleted successfully");
  } catch (e) {
    log("❌ Error deleting database: $e");
  }
}
