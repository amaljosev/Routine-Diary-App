import 'package:flutter/material.dart';
import 'package:routine/core/version/app_version.dart';
import 'package:routine/features/diary/presentation/pages/diary_screen.dart';
import 'package:routine/features/onboarding/onboarding_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _animationController.forward();
    _navigateToHome();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    // Reduced delay for better UX (2 seconds instead of 10 minutes)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!_hasNavigated && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final showOnboarding = prefs.getBool('showOnboarding') ?? true; 
      
      _hasNavigated = true;
      
      if (!showOnboarding) {
        // User has completed onboarding, go to diary
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DiaryScreen()),
        );
      } else {
        // First time user, show onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha:0.05),
              colorScheme.secondary.withValues(alpha:0.05),
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
                              color: colorScheme.primary.withValues(alpha:0.1),
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
                          'Pursuit',
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
                            color: colorScheme.onSurface.withValues(alpha:0.6),
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
                        // Theme-adaptive LinearProgressIndicator
                        LinearProgressIndicator(
                          backgroundColor: colorScheme.primary.withValues(alpha:0.1),
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
                                color: colorScheme.onSurface.withValues(alpha:0.5),
                              ),
                            ),
                            Text(
                              'v${AppVersion.version}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha:0.3),
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
    );
  }
}