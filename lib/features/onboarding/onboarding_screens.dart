import 'package:flutter/material.dart';
import 'package:routine/features/diary/presentation/pages/diary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _scaleController;
  
  int _currentPage = 0;
  
  // Data for each onboarding page
  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      icon: Icons.book_outlined,
      title: 'Write Your Story',
      description:
          'Capture your daily thoughts and moments in a secure personal diary.',
    ),
    OnboardingPageData(
      icon: Icons.storage_outlined,
      title: 'Offline & Private',
      description:
          'All entries are stored locally on your device. No internet required.',
    ),
    OnboardingPageData(
      icon: Icons.palette_outlined,
      title: 'Multiple Themes',
      description:
          'Switch between beautiful light, dark, and custom themes anytime.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Animation controllers for entry animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Floating particles background - increased to 50 particles
          _FloatingParticles(color: theme.colorScheme.primary),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Animated skip button
                AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeController,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: _currentPage < _pages.length - 1
                            ? TextButton(
                                onPressed: () {
                                  _pageController.animateToPage(
                                    _pages.length - 1,
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOutCubic,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                  textStyle: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text('Skip'),
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
                
                // PageView with animated transitions
                Expanded(
                  flex: 3,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      // Reset animations when page changes
                      _fadeController.reset();
                      _fadeController.forward();
                      _slideController.reset();
                      _slideController.forward();
                      _scaleController.reset();
                      _scaleController.forward();
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return AnimatedBuilder(
                        animation: Listenable.merge([
                          _fadeController,
                          _slideController,
                          _scaleController,
                        ]),
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeController.value,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                50 * (1 - _slideController.value),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.08,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Animated icon container
                                    Transform.scale(
                                      scale: 0.8 + (0.2 * _scaleController.value),
                                      child: Container(
                                        width: size.width * 0.35,
                                        height: size.width * 0.35,
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            colors: [
                                              theme.colorScheme.primary.withValues(alpha:0.2),
                                              theme.colorScheme.primary.withValues(alpha:0.05),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          page.icon,
                                          size: size.width * 0.18,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    
                                    SizedBox(height: size.height * 0.03),
                                    
                                    // Animated title
                                    SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.3),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _slideController,
                                          curve: Curves.easeOutQuad,
                                        ),
                                      ),
                                      child: Text(
                                        page.title,
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    
                                    SizedBox(height: size.height * 0.015),
                                    
                                    // Animated description
                                    SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.2),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _slideController,
                                          curve: Curves.easeOutQuad,
                                        ),
                                      ),
                                      child: Text(
                                        page.description,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // Animated page indicator
                AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeController,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: _currentPage == index ? 24 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: _currentPage == index
                                  ? LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary.withValues(alpha:0.7),
                                      ],
                                    )
                                  : null,
                              color: _currentPage == index
                                  ? null
                                  : theme.colorScheme.primary.withValues(alpha:0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: size.height * 0.02),
                
                // Animated button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.08,
                    vertical: size.height * 0.02,
                  ),
                  child: AnimatedBuilder(
                    animation: _scaleController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.95 + (0.05 * _scaleController.value),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_currentPage == _pages.length - 1) {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('showOnboarding', false);
                                
                                if (!mounted) return;
                                
                                // Animated navigation
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => 
                                        const DiaryScreen(),
                                    transitionsBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOutCubic,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              _currentPage == _pages.length - 1 
                                  ? 'Get Started' 
                                  : 'Next',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Floating particles background widget with more particles and faster movement
class _FloatingParticles extends StatelessWidget {
  final Color color;

  const _FloatingParticles({required this.color});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return IgnorePointer(
      child: Stack(
        children: List.generate(50, (index) { // Increased from 20 to 50 particles
          // More varied particle sizes
          final particleSize = 2.0 + (index % 8) * 4.0;
          
          // Distribute particles more evenly across screen
          final left = (index * 13.0 * (index % 3)) % size.width;
          final top = (index * 17.0 * (index % 2 + 1)) % size.height;
          
          // Faster animation durations (reduced from 4000+ to 1500-3000ms)
          final duration = Duration(milliseconds: 5000 + (index * 30) % 1500);
          
          // Varied delays for more organic movement
          final delay = Duration(milliseconds: (index * 50) % 2000);
          
          // Create different movement patterns
          final movementPattern = index % 3;
          
          return Positioned(
            left: left,
            top: top,
            child: _FloatingParticle(
              size: particleSize,
              color: color.withValues(alpha:0.05 + (index % 8) * 0.03),
              duration: duration,
              delay: delay,
              movementPattern: movementPattern,
            ),
          );
        }),
      ),
    );
  }
}

class _FloatingParticle extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final Duration delay;
  final int movementPattern; 

  const _FloatingParticle({
    required this.size,
    required this.color,
    required this.duration,
    required this.delay,
    required this.movementPattern,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    // Create different movement patterns for variety
    Offset endOffset;
    switch (widget.movementPattern) {
      case 0: // Vertical movement
        endOffset = Offset(0, widget.size * 6);
        break;
      case 1: // Horizontal movement
        endOffset = Offset(widget.size * 5, 0);
        break;
      case 2: // Diagonal movement
        endOffset = Offset(widget.size * 4, widget.size * 4);
        break;
      default:
        endOffset = Offset(widget.size * 3, widget.size * 3);
    }
    
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: endOffset,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
    
    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// Simple data class for each onboarding page
class OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}