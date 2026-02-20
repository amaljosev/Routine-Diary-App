import 'package:routine/core/theme/app_theme.dart';
import 'package:routine/features/diary/data/datasources/diary_local_data_source.dart';
import 'package:routine/features/diary/data/repository/diary_repo_implementation.dart';
import 'package:routine/features/diary/domain/repository/diary_repository.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/pages/diary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/settings/data/theme_repository_impl.dart';
import 'package:routine/features/settings/domain/theme_repository.dart';
import 'package:routine/features/settings/presentation/bloc/apptheme_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Diary dependencies
  final diaryLocalDataSource = DiaryLocalDataSource();
  final diaryRepository = DiaryRepositoryImpl(diaryLocalDataSource);

  // Theme dependencies
  final themeRepository = ThemeRepositoryImpl();

  runApp(
    MyApp(diaryRepository: diaryRepository, themeRepository: themeRepository),
  );
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
          create: (_) =>
              DiaryBloc(repository: diaryRepository)..add(LoadDiaryEntries()),
        ),
        // Theme BLoC
        BlocProvider(
          create: (_) =>
              ThemeBloc(repository: themeRepository)..add(LoadSavedTheme()),
        ),
      ],
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            final themeIndex = state.themeIndex;

            final safeIndex = themeIndex.clamp(0, allThemes.length - 1);

            final themeData = allThemes[safeIndex];

            final ThemeMode themeMode = safeIndex <= 3
                ? ThemeMode.light
                : ThemeMode.dark;

            return MaterialApp(
              title: 'Routine: Diary App',
              debugShowCheckedModeBanner: false,
              theme: themeData,
              darkTheme: themeData,
              themeMode: themeMode,
              home: const DiaryScreen(),
            );
          },
        ),
      ),
    );
  }
}
