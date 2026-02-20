import 'dart:developer';

import 'package:routine/core/theme/app_theme.dart';
import 'package:routine/features/diary/data/datasources/diary_local_data_source.dart';
import 'package:routine/features/diary/data/repository/diary_repo_implementation.dart';
import 'package:routine/features/diary/domain/repository/diary_repository.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/pages/diary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import 'package:routine/features/settings/data/theme_repository_impl.dart';
import 'package:routine/features/settings/domain/theme_repository.dart';
import 'package:routine/features/settings/presentation/bloc/apptheme_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Diary dependencies
  final diaryLocalDataSource = DiaryLocalDataSource();
  final diaryRepository = DiaryRepositoryImpl(diaryLocalDataSource);

  // Theme dependencies
  final themeRepository = ThemeRepositoryImpl();

  runApp(MyApp(
    diaryRepository: diaryRepository,
    themeRepository: themeRepository,
  ));
}

class MyApp extends StatelessWidget {
  final DiaryRepository diaryRepository;
  final ThemeRepository themeRepository;

  const MyApp({
    super.key,
    required this.diaryRepository,
    required this.themeRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Diary BLoC
        BlocProvider(
          create: (_) => DiaryBloc(repository: diaryRepository)
            ..add(LoadDiaryEntries()),
        ),
        // Theme BLoC
        BlocProvider(
          create: (_) => ThemeBloc(repository: themeRepository)
            ..add(LoadSavedTheme()),
        ),
      ],
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.0),
        ),
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            // Map themeIndex (0-5) to actual ThemeData
            final themeIndex = state.themeIndex;
            late final ThemeData themeData;
            late final ThemeMode themeMode;

            if (themeIndex < 3) {
              // Light themes
              final lightThemes = [lightTheme1, lightTheme2, lightTheme3];
              themeData = lightThemes[themeIndex];
              themeMode = ThemeMode.light;
            } else {
              // Dark themes
              final darkThemes = [darkTheme1, darkTheme2, darkTheme3];
              themeData = darkThemes[themeIndex - 3];
              themeMode = ThemeMode.dark;
            }

            return MaterialApp(
              title: 'Routine: Diary App',
              debugShowCheckedModeBanner: false,
              theme: themeData,
              themeMode: themeMode, // Force light/dark based on selection
              home: const DiaryScreen(),
            );
          },
        ),
      ),
    );
  }
}
Future<void> resetDatabase() async {
  final dbPath = await getDatabasesPath();
  final habitPath = join(dbPath, 'habits.db');
  final diaryPath = join(dbPath, 'routine_diary.db');
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
