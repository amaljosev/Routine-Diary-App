import 'package:routine/core/config/secrets.dart';
import 'package:routine/core/network/network_info.dart';
import 'package:routine/core/services/showcase_prefs_service.dart';
import 'package:routine/core/theme/app_theme.dart';
import 'package:routine/features/app_lock/data/datasources/biometric_local_auth_datasource.dart';
import 'package:routine/features/app_lock/data/datasources/shared_preferences_datasource.dart';
import 'package:routine/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:routine/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';
import 'package:routine/features/backup/data/datasources/diary_local_datasource.dart'
    as backup_local;
import 'package:routine/features/backup/data/datasources/drive_remote_datasource.dart';
import 'package:routine/features/backup/data/datasources/google_auth_datasource.dart';
import 'package:routine/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:routine/features/backup/domain/repositories/backup_repository.dart';
import 'package:routine/features/backup/presentation/bloc/backup_bloc.dart';
import 'package:routine/features/diary/data/datasources/diary_local_data_source.dart';
import 'package:routine/features/diary/data/repository/diary_repo_implementation.dart';
import 'package:routine/features/diary/domain/repository/diary_repository.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:routine/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:routine/features/onboarding/presentation/pages/splash_screen.dart';
import 'package:routine/features/premium/data/datasources/premium_iap_datasource.dart';
import 'package:routine/features/premium/premium_factory.dart';
import 'package:routine/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:routine/features/settings/data/theme_repository_impl.dart';
import 'package:routine/features/settings/domain/theme_repository.dart';
import 'package:routine/features/settings/presentation/bloc/apptheme_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const PageTransitionsTheme _flatPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: ZoomPageTransitionsBuilder(
      backgroundColor: Colors.transparent,
    ),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PremiumIapDataSource.instance.init();
  final onboardingRepository = OnboardingRepositoryImpl();
  final diaryLocalDataSource = DiaryLocalDataSource();
  final diaryRepository = DiaryRepositoryImpl(diaryLocalDataSource);
  final themeRepository = ThemeRepositoryImpl();
  final biometricDataSource = BiometricLocalAuthDataSource();
  final prefsDataSource = SharedPreferencesDataSource();
  final appLockRepository = AppLockRepositoryImpl(
    biometricDataSource: biometricDataSource,
    prefsDataSource: prefsDataSource,
  );

  final googleAuthDataSource = GoogleAuthDataSource();
  final driveRemoteDataSource = DriveRemoteDataSource(googleAuthDataSource);
  final diaryBackupLocalDataSource = backup_local.DiaryBackupLocalDataSource();
  final networkInfo = NetworkInfoImpl();
  final backupRepository = BackupRepositoryImpl(
    authDataSource: googleAuthDataSource,
    remoteDataSource: driveRemoteDataSource,
    localDataSource: diaryBackupLocalDataSource,
    networkInfo: networkInfo,
  );
  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabaseAnonKey,
  );
  await ShowcasePrefsService.init();
  runApp(
    MyApp(
      onboardingRepository: onboardingRepository,
      diaryRepository: diaryRepository,
      themeRepository: themeRepository,
      appLockRepository: appLockRepository,
      backupRepository: backupRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final OnboardingRepository onboardingRepository;
  final DiaryRepository diaryRepository;
  final ThemeRepository themeRepository;
  final AppLockRepository appLockRepository;
  final BackupRepository backupRepository;

  const MyApp({
    super.key,
    required this.onboardingRepository,
    required this.diaryRepository,
    required this.themeRepository,
    required this.appLockRepository,
    required this.backupRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PremiumFactory.createBloc()
            ..add(const PremiumStarted()), 
        ),
        RepositoryProvider<OnboardingRepository>(
          create: (_) => onboardingRepository,
        ),

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
        BlocProvider(
          create: (_) =>
              BackupBloc(repository: backupRepository)
                ..add(const BackupSilentSignInRequested()),
        ),
      ],
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            final ThemeData themeData;
            if (state.isCustomThemeActive && state.customThemeData != null) {
              themeData = state.customThemeData!.copyWith(
                pageTransitionsTheme: _flatPageTransitions,
              );
            } else {
              final safeIndex = state.themeIndex.clamp(0, allThemes.length - 1);
              themeData = allThemes[safeIndex].copyWith(
                pageTransitionsTheme: _flatPageTransitions,
              );
            }

            final ThemeMode themeMode =
                themeData.colorScheme.brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light;

            return MaterialApp(
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
