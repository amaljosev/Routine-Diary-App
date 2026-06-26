// lib/main.dart
import 'package:flutter_bloc/flutter_bloc.dart';
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
          create: (_) =>
              PremiumFactory.createBloc()..add(const PremiumStarted()),
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
          create: (_) => AppLockBloc(repository: appLockRepository)
            ..add(LoadAppLockSettings()),
        ),
        BlocProvider(
          create: (_) => BackupBloc(repository: backupRepository)
            ..add(const BackupSilentSignInRequested()),
        ),
      ],
      child: _AppListeners(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              final ThemeData themeData;
              if (state.isCustomThemeActive && state.customThemeData != null) {
                themeData = state.customThemeData!.copyWith(
                  pageTransitionsTheme: _flatPageTransitions,
                );
              } else {
                final safeIndex =
                    state.themeIndex.clamp(0, allThemes.length - 1);
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
      ),
    );
  }
}

/// Hosts all top-level BlocListeners that coordinate cross-bloc side effects.
/// Extracted into its own widget to keep [MyApp.build] readable.
class _AppListeners extends StatelessWidget {
  final Widget child;
  const _AppListeners({required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ── Subscription expiry → deactivate custom theme ─────────────────
        //
        // Fires once per session on the false → true transition of
        // subscriptionExpired.
        //
        // KEY CHANGE: fires DeactivateCustomTheme (not ChangeTheme(0)).
        // DeactivateCustomTheme switches the active theme to 0 while
        // preserving customThemeModel in state — so the user's theme config
        // is safe and can be restored when they re-subscribe.
        //
        // addPostFrameCallback defers the event to the next frame so it never
        // fires synchronously during a build phase (avoids
        // "setState called during build" crashes).
        BlocListener<PremiumBloc, PremiumState>(
          listenWhen: (prev, curr) =>
              !prev.subscriptionExpired && curr.subscriptionExpired,
          listener: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context
                    .read<ThemeBloc>()
                    .add( DeactivateCustomTheme());
              }
            });
          },
        ),

        // ── Successful (re-)subscription → auto-restore custom theme ───────
        //
        // Fires on the false → true transition of isPremium (covers both
        // first-time subscribers and lapsed users who re-subscribe).
        //
        // If customThemeModel is present in ThemeState we immediately
        // re-apply it — the user gets their theme back without any manual
        // steps. For first-time subscribers customThemeModel is null, so
        // nothing happens here and they can create their theme normally.
        BlocListener<PremiumBloc, PremiumState>(
          listenWhen: (prev, curr) => !prev.isPremium && curr.isPremium,
          listener: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              final customModel =
                  context.read<ThemeBloc>().state.customThemeModel;
              if (customModel != null) {
                context
                    .read<ThemeBloc>()
                    .add(ApplyCustomTheme(customModel));
              }
            });
          },
        ),
      ],
      child: child,
    );
  }
}