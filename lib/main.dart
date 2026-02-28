import 'package:routine/core/config/secrets.dart';
import 'package:routine/core/theme/app_theme.dart';
import 'package:routine/features/app_lock/data/datasources/biometric_local_auth_datasource.dart';
import 'package:routine/features/app_lock/data/datasources/shared_preferences_datasource.dart';
import 'package:routine/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:routine/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';
import 'package:routine/features/diary/data/datasources/diary_local_data_source.dart';
import 'package:routine/features/diary/data/repository/diary_repo_implementation.dart';
import 'package:routine/features/diary/domain/repository/diary_repository.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/onboarding/splash_screen.dart';
import 'package:routine/features/settings/data/theme_repository_impl.dart';
import 'package:routine/features/settings/domain/theme_repository.dart';
import 'package:routine/features/settings/presentation/bloc/apptheme_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final diaryLocalDataSource = DiaryLocalDataSource();
  final diaryRepository = DiaryRepositoryImpl(diaryLocalDataSource);
  final themeRepository = ThemeRepositoryImpl();
  final biometricDataSource = BiometricLocalAuthDataSource();
  final prefsDataSource = SharedPreferencesDataSource();
  final appLockRepository = AppLockRepositoryImpl(
    biometricDataSource: biometricDataSource,
    prefsDataSource: prefsDataSource,
  );
  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabaseAnonKey,
  );

  runApp(
    MyApp(
      diaryRepository: diaryRepository,
      themeRepository: themeRepository,
      appLockRepository: appLockRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final DiaryRepository diaryRepository;
  final ThemeRepository themeRepository;
  final AppLockRepository appLockRepository;

  const MyApp({
    super.key,
    required this.diaryRepository,
    required this.themeRepository,
    required this.appLockRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              DiaryBloc(repository: diaryRepository)..add(LoadDiaryEntries()),
        ),
        BlocProvider(
          create: (_) =>
              ThemeBloc(repository: themeRepository)..add(LoadSavedTheme()),
        ),
        BlocProvider(
          create: (_) =>
              AppLockBloc(repository: appLockRepository)
                ..add(LoadAppLockSettings()),
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
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
