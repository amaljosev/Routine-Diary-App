import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/services/app_update_service.dart';
import 'package:routine/features/app_lock/presentation/widgets/lock_gate.dart';
import 'package:routine/features/onboarding/pages/onboarding_screen.dart';
import 'package:routine/features/onboarding/presentation/bloc/splash_bloc.dart';
import 'package:routine/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:routine/core/version/app_version.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashBloc(
        repository: context.read<OnboardingRepository>(),
      )..add(SplashStarted()),
      child: const SplashView(),
    );
  }
}

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Non-blocking background task
    AppUpdateService().checkForBackgroundUpdate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final colorScheme = theme.colorScheme;

    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateToOnboarding) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        } else if (state is SplashNavigateToLockGate) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LockGate()),
          );
        } else if (state is SplashError) {
          // Show error and maybe fallback to a safe screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
          // Optionally navigate to a fallback screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LockGate()),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.secondary.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated app icon/logo
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: Container(
                              height: size.width * 0.3,
                              width: size.width * 0.3,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/icons/routine_icon.png',
                                  height: size.width * 0.2,
                                  width: size.width * 0.2,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.fitness_center,
                                      size: size.width * 0.15,
                                      color: colorScheme.primary,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: size.height * 0.03),

                    // App name with animation
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _opacityAnimation.value,
                          child: Text(
                            'Routine',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Tagline
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _opacityAnimation.value * 0.7,
                          child: Text(
                            "Capture your journey",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: size.height * 0.06),

                    // Theme-adaptive progress bar
                    SizedBox(
                      width: size.width * 0.6,
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            backgroundColor:
                                colorScheme.primary.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),

                          SizedBox(height: size.height * 0.01),

                          // Loading text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Loading...',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              Text(
                                'v${AppVersion.version}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}