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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await resetDatabase();
  final diaryLocalDataSource = DiaryLocalDataSource();
  final DiaryRepository diaryRepository = DiaryRepositoryImpl(
    diaryLocalDataSource,
  );

  runApp(
    MyApp(
      diaryRepo: diaryRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.diaryRepo,
  });

  final DiaryRepository diaryRepo;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        
        BlocProvider(
          create: (_) =>
              DiaryBloc(repository: diaryRepo)..add(LoadDiaryEntries()),
        ),
      ],
      child: MediaQuery(
        
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
        child: MaterialApp(
          title: 'Routine: Diary App',
          debugShowCheckedModeBanner: false,
           theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          home: const DiaryScreen(),
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
