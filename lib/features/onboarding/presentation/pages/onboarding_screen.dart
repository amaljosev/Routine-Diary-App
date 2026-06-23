import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/diary/presentation/pages/diary_screen.dart';
import 'package:routine/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:routine/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          OnboardingBloc(repository: context.read<OnboardingRepository>())
            ..add(OnboardingStarted()),
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

  // Cycles through the 3 available background images.
  static const _bgImages = [
    'assets/img/onboarding/test_1.png',
    'assets/img/onboarding/test_2.png',
    'assets/img/onboarding/test_3.png',
  ];

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      imagePath: 'assets/img/onboarding/test_1.png',
      title: 'Your Personal Diary',
      description:
          'Capture your daily thoughts, feelings, and moments in one beautiful space. Add titles, moods, and rich descriptions to every entry.',
    ),
    OnboardingPageData(
      imagePath: 'assets/img/onboarding/test_2.png',
      title: 'Express Yourself',
      description:
          'Make each entry unique with stickers, photos, and custom backgrounds. Choose from multiple fonts and express your mood with emojis.',
    ),
    OnboardingPageData(
      imagePath: 'assets/img/onboarding/test_3.png',
      title: 'Secure & Private',
      description:
          'Your diary is protected by PIN lock, device biometrics, or a personal security question — keeping your entries safe no matter where they live.',
    ),
    OnboardingPageData(
      imagePath: 'assets/img/onboarding/test_1.png',
      title: 'Memory Timeline',
      description:
          'Browse your entries visually with the calendar view. See your journey through time and relive special moments with ease.',
    ),
    OnboardingPageData(
      imagePath: 'assets/img/onboarding/test_2.png',
      title: 'Make It Yours',
      description:
          'Build your perfect look with fully custom themes — pick accent colours, switch between light and dark modes, and style every detail to match your vibe.',
    ),
    OnboardingPageData(
      imagePath: 'assets/img/onboarding/test_3.png',
      title: 'Backed Up to the Cloud',
      description:
          'Never lose a memory. Your diary is automatically backed up to Google Drive so your entries are safe, synced, and always with you.',
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

  /// Full-bleed background image for the primary-coloured panel.
  Widget _buildBgImage({
    required String imagePath,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    Widget img = Image.asset(imagePath, fit: fit);
    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius, child: img);
    }
    return img;
  }

  /// Shared helper: step counter label ("01 / 06") shown at the top of the card.
  Widget _buildStepCounter(BuildContext context, int index, int totalPages) {
    final theme = Theme.of(context);
    return Text(
      '${(index + 1).toString().padLeft(2, '0')} '
      '/ '
      '${totalPages.toString().padLeft(2, '0')}',
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
  }

  /// Shared helper: animated title + description column.
  Widget _buildCardText(
    BuildContext context,
    OnboardingPageData page, {
    TextAlign textAlign = TextAlign.left,
    double titleFontSize = 26,
    double bodyFontSize = 15,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: textAlign == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Opacity(
          opacity: _fadeController.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _slideController.value)),
            child: Text(
              page.title,
              textAlign: textAlign,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                fontSize: titleFontSize,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: _fadeController.value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - _slideController.value)),
            child: Text(
              page.description,
              textAlign: textAlign,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.65,
                fontSize: bodyFontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Phone portrait: full-screen image bg, white card slides up ─────────────

  Widget _buildSplitCardPortrait(
    BuildContext context,
    OnboardingPageData page,
    Size size,
    int index,
    int totalPages,
  ) {
    // Card occupies roughly the bottom 48 % of the screen.
    final cardHeight = size.height * 0.48;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // ── Full-screen background image ───────────────────────────────────
        Positioned.fill(
          child: _buildBgImage(imagePath: page.imagePath),
        ),

        // ── White card ─────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: cardHeight),
          // Extra bottom padding reserves space for the fixed controls overlay.
          padding: EdgeInsets.fromLTRB(
            28,
            28,
            28,
            80 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStepCounter(context, index, totalPages),
              const SizedBox(height: 14),
              _buildCardText(context, page),
            ],
          ),
        ),
      ],
    );
  }

  // ── Phone landscape: left half image, white card on right ──────────────────

  Widget _buildSplitCardLandscape(
    BuildContext context,
    OnboardingPageData page,
    Size size,
    int index,
    int totalPages,
  ) {
    return Row(
      children: [
        // ── Image area (left panel) ────────────────────────────────────────
        SizedBox(
          width: size.width * 0.42,
          height: double.infinity,
          child: _buildBgImage(
            imagePath: page.imagePath,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(0),
            ),
          ),
        ),

        // ── White card ─────────────────────────────────────────────────────
        Expanded(
          child: Container(
            height: double.infinity,
            padding: EdgeInsets.fromLTRB(
              28,
              28,
              28,
              80 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepCounter(context, index, totalPages),
                  const SizedBox(height: 14),
                  _buildCardText(
                    context,
                    page,
                    titleFontSize: 22,
                    bodyFontSize: 13,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Tablet: wider left image panel, generous right card ───────────────────

  Widget _buildSplitCardTablet(
    BuildContext context,
    OnboardingPageData page,
    Size size,
    int index,
    int totalPages,
  ) {
    final isLandscape = size.width > size.height;
    final leftFraction = isLandscape ? 0.44 : 0.40;

    return Row(
      children: [
        // ── Image area (left panel) ────────────────────────────────────────
        SizedBox(
          width: size.width * leftFraction,
          height: double.infinity,
          child: _buildBgImage(imagePath: page.imagePath),
        ),

        // ── White card ─────────────────────────────────────────────────────
        Expanded(
          child: Container(
            height: double.infinity,
            padding: EdgeInsets.fromLTRB(
              40,
              40,
              40,
              100 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(40),
              ),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepCounter(context, index, totalPages),
                  const SizedBox(height: 20),
                  _buildCardText(
                    context,
                    page,
                    titleFontSize: 32,
                    bodyFontSize: 17,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = _isTablet(context);
    final isPhoneLandscape = _isPhoneLandscape(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    final controlsPadH = isTablet ? 40.0 : 28.0;
    final controlsPadB = (safeBottom > 0 ? safeBottom : 16.0) + 8.0;

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
            // ── 1. PageView ───────────────────────────────────────────────
            BlocBuilder<OnboardingBloc, OnboardingState>(
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
                        builder: (context, _) => isTablet
                            ? _buildSplitCardTablet(
                                context, page, size, index, state.totalPages)
                            : isPhoneLandscape
                                ? _buildSplitCardLandscape(
                                    context, page, size, index, state.totalPages)
                                : _buildSplitCardPortrait(
                                    context, page, size, index, state.totalPages),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // ── 2. Skip button (top-right, over the image area) ───────────
            BlocBuilder<OnboardingBloc, OnboardingState>(
              builder: (context, state) {
                if (state is OnboardingLoaded && !state.isLastPage) {
                  return SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: isTablet ? 16 : 10,
                          right: isTablet ? 28 : 16,
                        ),
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
                            foregroundColor: Colors.white.withValues(alpha: 0.85),
                            textStyle: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Skip'),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // ── 3. Bottom controls (dots + next / get-started) ────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BlocBuilder<OnboardingBloc, OnboardingState>(
                builder: (context, state) {
                  if (state is OnboardingLoaded) {
                    final leftInset = (!isTablet && !isPhoneLandscape)
                        ? 0.0
                        : isTablet
                            ? size.width *
                                (size.width > size.height ? 0.44 : 0.40)
                            : size.width * 0.42;

                    return Padding(
                      padding: EdgeInsets.only(
                        left: leftInset + controlsPadH,
                        right: controlsPadH,
                        bottom: controlsPadB,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Dots indicator
                          Row(
                            children: List.generate(
                              state.totalPages,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.only(right: 6),
                                width: state.currentPage == index
                                    ? (isTablet ? 28 : 22)
                                    : (isTablet ? 10 : 8),
                                height: isTablet ? 10 : 8,
                                decoration: BoxDecoration(
                                  color: state.currentPage == index
                                      ? Colors.purple.shade700
                                      :  Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          if (!state.isLastPage)
                            AnimatedBuilder(
                              animation: _scaleController,
                              builder: (context, _) => Transform.scale(
                                scale: 0.95 + 0.05 * _scaleController.value,
                                child: SizedBox(
                                  width: isTablet ? 60 : 52,
                                  height: isTablet ? 60 : 52,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      context
                                          .read<OnboardingBloc>()
                                          .add(NextPageTapped());
                                      _pageController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 600),
                                        curve: Curves.easeInOutCubic,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.purple.shade700,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                      shape: const CircleBorder(),
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: isTablet ? 26 : 22,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            AnimatedBuilder(
                              animation: _scaleController,
                              builder: (context, _) => Transform.scale(
                                scale: 0.95 + 0.05 * _scaleController.value,
                                child: SizedBox(
                                  height: isTablet ? 56 : 50,
                                  child: ElevatedButton(
                                    onPressed: () => context
                                        .read<OnboardingBloc>()
                                        .add(GetStartedTapped()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                           Colors.purple.shade700,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 36 : 28,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Text(
                                      'Get Started',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        fontSize: isTablet ? 18 : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
    );
  }
}

class OnboardingPageData {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}