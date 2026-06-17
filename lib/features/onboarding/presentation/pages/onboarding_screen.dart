import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/widgets/floating_particles.dart';
import 'package:routine/features/diary/presentation/pages/diary_screen.dart';
import 'package:routine/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:routine/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingBloc(
        repository: context.read<OnboardingRepository>(),
      )..add(OnboardingStarted()),
      child: const OnboardingView(),
    );
  }
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _scaleController;

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      icon: Icons.menu_book_outlined,
      title: 'Your Personal Diary',
      description:
          'Capture your daily thoughts, feelings, and experiences in a beautiful, private space. Add titles, moods, and rich descriptions to every entry.',
    ),
    OnboardingPageData(
      icon: Icons.auto_awesome_outlined,
      title: 'Express Yourself',
      description:
          'Make each entry unique with stickers, photos, and custom backgrounds. Choose from multiple fonts and express your mood with emojis.',
    ),
    OnboardingPageData(
      icon: Icons.lock_outline,
      title: 'Secure & Private',
      description:
          'Your diary stays on your device. Add an extra layer of security with PIN lock, device biometrics, or a personal security question.',
    ),
    OnboardingPageData(
      icon: Icons.calendar_month_outlined,
      title: 'Memory Timeline',
      description:
          'Browse your entries visually with the calendar view. See your journey through time and relive special moments with ease.',
    ),
    OnboardingPageData(
      icon: Icons.palette_outlined,
      title: 'Your Style, Your Way',
      description:
          'Switch between light and dark themes, customize fonts, and download new sticker packs to keep your diary fresh and personal.',
    ),
  ];

  // ── helpers ──────────────────────────────────────────────────────────────────

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  /// True when the phone is in landscape (width > height) but NOT a tablet.
  bool _isPhoneLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return !_isTablet(context) && size.width > size.height;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

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

  void _onPageChanged(int index) {
    context.read<OnboardingBloc>().add(PageChanged(index));
    _fadeController
      ..reset()
      ..forward();
    _slideController
      ..reset()
      ..forward();
    _scaleController
      ..reset()
      ..forward();
  }

  // ── page content builders ─────────────────────────────────────────────────

  /// Phone portrait layout: icon above, text below, wrapped in a scroll view
  /// so it never overflows when vertical space is limited.
  Widget _buildPhonePortraitContent(
    BuildContext context,
    OnboardingPageData page,
    Size size,
  ) {
    final theme = Theme.of(context);
    // Use smaller proportions so content breathes at any height.
    final iconContainerSize = size.width * 0.30;
    final iconSize = size.width * 0.15;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.08,
          // Give vertical breathing room without fixed large gaps.
          vertical: size.height * 0.02,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: size.height * 0.02),
            // Icon circle
            AnimatedBuilder(
              animation: _scaleController,
              builder: (context, _) => Transform.scale(
                scale: 0.8 + (0.2 * _scaleController.value),
                child: Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    page.icon,
                    size: iconSize,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.025),
            // Title
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _slideController, curve: Curves.easeOutQuad)),
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
            // Description
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _slideController, curve: Curves.easeOutQuad)),
              child: Text(
                page.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: size.height * 0.02),
          ],
        ),
      ),
    );
  }

  /// Phone landscape layout: icon on the left, text on the right.
  /// Mirrors the tablet layout but sized for a smaller screen.
  Widget _buildPhoneLandscapeContent(
    BuildContext context,
    OnboardingPageData page,
    Size size,
  ) {
    final theme = Theme.of(context);
    // In landscape height is the short side — base icon on that.
    final iconContainerSize = size.height * 0.38;
    final iconSize = size.height * 0.20;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.08,
          vertical: size.height * 0.06,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: icon
            AnimatedBuilder(
              animation: _scaleController,
              builder: (context, _) => Transform.scale(
                scale: 0.8 + (0.2 * _scaleController.value),
                child: Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    page.icon,
                    size: iconSize,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),

            SizedBox(width: size.width * 0.06),

            // Right: title + description
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.2, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: _slideController, curve: Curves.easeOutQuad)),
                    child: Text(
                      page.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: _slideController, curve: Curves.easeOutQuad)),
                    child: Text(
                      page.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tablet layout: icon on left, larger text on right.
  Widget _buildTabletContent(
    BuildContext context,
    OnboardingPageData page,
    Size size,
  ) {
    final theme = Theme.of(context);
    final iconContainerSize = size.shortestSide * 0.22;
    final iconSize = size.shortestSide * 0.12;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.10,
          vertical: size.height * 0.04,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: icon
            AnimatedBuilder(
              animation: _scaleController,
              builder: (context, _) => Transform.scale(
                scale: 0.8 + (0.2 * _scaleController.value),
                child: Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    page.icon,
                    size: iconSize,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),

            SizedBox(width: size.width * 0.06),

            // Right: title + description
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.2, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: _slideController, curve: Curves.easeOutQuad)),
                    child: Text(
                      page.title,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: _slideController, curve: Curves.easeOutQuad)),
                    child: Text(
                      page.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                        height: 1.6,
                        fontSize: 17,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = _isTablet(context);
    final isPhoneLandscape = _isPhoneLandscape(context);

    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingCompleted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const DiaryScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            FloatingParticles(color: theme.colorScheme.primary),
            SafeArea(
              child: Column(
                children: [
                  // ── Skip button ───────────────────────────────────────────
                  BlocBuilder<OnboardingBloc, OnboardingState>(
                    builder: (context, state) {
                      if (state is OnboardingLoaded && !state.isLastPage) {
                        return Padding(
                          padding: EdgeInsets.only(
                            top: isTablet ? 12 : 8,
                            right: isTablet ? 24 : 16,
                          ),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: TextButton(
                              onPressed: () {
                                context
                                    .read<OnboardingBloc>()
                                    .add(SkipToEndTapped());
                                _pageController.animateToPage(
                                  state.totalPages - 1,
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
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // ── PageView ──────────────────────────────────────────────
                  Expanded(
                    child: BlocBuilder<OnboardingBloc, OnboardingState>(
                      builder: (context, state) {
                        if (state is OnboardingLoaded) {
                          return PageView.builder(
                            controller: _pageController,
                            onPageChanged: _onPageChanged,
                            itemCount: state.totalPages,
                            itemBuilder: (context, index) {
                              final page = _pages[index];
                              return AnimatedBuilder(
                                animation: Listenable.merge([
                                  _fadeController,
                                  _slideController,
                                  _scaleController,
                                ]),
                                builder: (context, _) => Opacity(
                                  opacity: _fadeController.value,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      50 * (1 - _slideController.value),
                                    ),
                                    child: isTablet
                                        ? _buildTabletContent(
                                            context, page, size)
                                        : isPhoneLandscape
                                            ? _buildPhoneLandscapeContent(
                                                context, page, size)
                                            : _buildPhonePortraitContent(
                                                context, page, size),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  // ── Page indicator ────────────────────────────────────────
                  BlocBuilder<OnboardingBloc, OnboardingState>(
                    builder: (context, state) {
                      if (state is OnboardingLoaded) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            state.totalPages,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: EdgeInsets.symmetric(
                                horizontal: isTablet ? 8 : 6,
                              ),
                              width: state.currentPage == index ? 28 : 10,
                              height: isTablet ? 12 : 10,
                              decoration: BoxDecoration(
                                gradient: state.currentPage == index
                                    ? LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.primary
                                              .withValues(alpha: 0.7),
                                        ],
                                      )
                                    : null,
                                color: state.currentPage == index
                                    ? null
                                    : theme.colorScheme.primary
                                        .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  SizedBox(height: size.height * 0.015),

                  // ── Action button ─────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width *
                          (isTablet
                              ? 0.25
                              : isPhoneLandscape
                                  ? 0.20
                                  : 0.08),
                      vertical: size.height * 0.015,
                    ),
                    child: BlocBuilder<OnboardingBloc, OnboardingState>(
                      builder: (context, state) {
                        if (state is OnboardingLoaded) {
                          return AnimatedBuilder(
                            animation: _scaleController,
                            builder: (context, _) => Transform.scale(
                              scale: 0.95 + (0.05 * _scaleController.value),
                              child: SizedBox(
                                width: double.infinity,
                                // Slightly shorter button in landscape to save space.
                                height: isTablet
                                    ? 60
                                    : isPhoneLandscape
                                        ? 44
                                        : 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (state.isLastPage) {
                                      context
                                          .read<OnboardingBloc>()
                                          .add(GetStartedTapped());
                                    } else {
                                      context
                                          .read<OnboardingBloc>()
                                          .add(NextPageTapped());
                                      _pageController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 600),
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
                                    state.isLastPage ? 'Get Started' : 'Next',
                                    style:
                                        theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      fontSize: isTablet ? 18 : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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