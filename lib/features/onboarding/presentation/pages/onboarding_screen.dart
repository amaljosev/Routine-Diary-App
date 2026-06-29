import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/constants/app_constants.dart';
import 'package:routine/features/diary/presentation/pages/diary_screen.dart';
import 'package:routine/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:routine/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

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

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      imagePath: 'assets/img/onboarding/boarding_1.webp',
      title: 'Your Personal Diary',
      description:
          'Capture your daily thoughts, feelings, and moments in one beautiful space. Add titles, moods, and rich descriptions to every entry.',
    ),
    OnboardingPageData(
      imagePath: 'assets/img/onboarding/boarding_2.webp',
      title: 'Express Yourself',
      description:
          'Make each entry unique with stickers, photos, and custom backgrounds. Choose from multiple fonts and express your mood with emojis.',
    ),
    OnboardingPageData(
      imagePath: 'assets/img/onboarding/boarding_3.webp',
      title: 'Secure & Private',
      description:
          'Your diary is protected by PIN lock, device biometrics, or a personal security question — keeping your entries safe no matter where they live.',
    ),
  ];

  // ── helpers ───────────────────────────────────────────────────────────────

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

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

  // ── shared builders ───────────────────────────────────────────────────────

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

  Widget _buildStepCounter(BuildContext context, int index, int totalPages) {
    final theme = Theme.of(context);
    return Text(
      '${(index + 1).toString().padLeft(2, '0')} / ${totalPages.toString().padLeft(2, '0')}',
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildCardText(
    BuildContext context,
    OnboardingPageData page, {
    TextAlign textAlign = TextAlign.left,
    double? titleFontSize,
    double? bodyFontSize,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: textAlign == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_fadeController, _slideController]),
          builder: (context, _) => Opacity(
            opacity: _fadeController.value.clamp(0.0, 1.0),
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
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: Listenable.merge([_fadeController, _slideController]),
          builder: (context, _) => Opacity(
            opacity: _fadeController.value.clamp(0.0, 1.0),
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
        ),
      ],
    );
  }

  // ── bottom controls ───────────────────────────────────────────────────────

  /// The dots + next arrow OR dots + disclaimer + get-started button.
  /// Rendered as a Column so the disclaimer never overflows a fixed-height Row.
  Widget _buildBottomControls(
    BuildContext context,
    OnboardingState state,
    double leftInset,
    double padH,
    double padB,
    bool isTablet,
  ) {
    if (state is! OnboardingLoaded) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        state.totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 6),
          width: state.currentPage == index ? (isTablet ? 28 : 22) : (isTablet ? 10 : 8),
          height: isTablet ? 10 : 8,
          decoration: BoxDecoration(
            color: state.currentPage == index
                ? Colors.purple.shade700
                : Colors.purple.shade100,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );

    if (!state.isLastPage) {
      // ── Pages 1 & 2: dots left, arrow right ──────────────────────────────
      return Padding(
        padding: EdgeInsets.only(
          left: leftInset + padH,
          right: padH,
          bottom: padB,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            dots,
            const Spacer(),
            AnimatedBuilder(
              animation: _scaleController,
              builder: (context, _) => Transform.scale(
                scale: 0.95 + 0.05 * _scaleController.value,
                child: SizedBox(
                  width: isTablet ? 60 : 52,
                  height: isTablet ? 60 : 52,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<OnboardingBloc>().add(NextPageTapped());
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
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
            ),
          ],
        ),
      );
    }

    // ── Last page: dots left, disclaimer + button stacked on the right ────
    return Padding(
      padding: EdgeInsets.only(
        left: leftInset + padH,
        right: padH,
        bottom: padB,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Dots sit at the bottom of the row, aligned with the button
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: dots,
          ),
          const Spacer(),
          // Column: disclaimer text above, button below
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Disclaimer ──────────────────────────────────────────────
              ConstrainedBox(
                // Cap width so it wraps rather than overflows on large screens
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 320 : 220,
                ),
                child: Text.rich(
                  TextSpan(
                    text: 'By continuing, you accept our ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      fontSize: isTablet ? 12 : 10.5,
                      height: 1.5,
                    ),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => _launchURL(context, AppConstants.privacyPolicy),
                          child: Text(
                            'Privacy Policy',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.purple.shade700,
                              fontSize: isTablet ? 12 : 10.5,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: ' & ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          fontSize: isTablet ? 12 : 10.5,
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => _launchURL(context, AppConstants.termsAndConditions),
                          child: Text(
                            'Terms',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.purple.shade700,
                              fontSize: isTablet ? 12 : 10.5,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 10),
              // ── Get Started button ───────────────────────────────────────
              AnimatedBuilder(
                animation: _scaleController,
                builder: (context, _) => Transform.scale(
                  scale: 0.95 + 0.05 * _scaleController.value,
                  child: SizedBox(
                    height: isTablet ? 56 : 50,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.read<OnboardingBloc>().add(GetStartedTapped()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
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
                        style: theme.textTheme.labelLarge?.copyWith(
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
        ],
      ),
    );
  }

  // ── layout builders ───────────────────────────────────────────────────────

  /// Phone portrait: full-screen image, card slides up from bottom.
  /// Card uses a SingleChildScrollView so text never overflows at large font sizes.
  Widget _buildSplitCardPortrait(
    BuildContext context,
    OnboardingPageData page,
    Size size,
    int index,
    int totalPages,
  ) {
    // Reserve space for the fixed bottom controls overlay (~90 px + safe area).
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final controlsReserve = 90.0 + safeBottom;
    // Card minimum height is ~45 % of screen; it can grow if text is large.
    final cardMinHeight = size.height * 0.45;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Full-screen background
        Positioned.fill(child: _buildBgImage(imagePath: page.imagePath)),

        // Scrollable card
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: cardMinHeight),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(28, 28, 28, controlsReserve),
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
          ),
        ),
      ],
    );
  }

  /// Phone landscape: image left, scrollable card right.
  Widget _buildSplitCardLandscape(
    BuildContext context,
    OnboardingPageData page,
    Size size,
    int index,
    int totalPages,
  ) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final controlsReserve = 90.0 + safeBottom;

    return Row(
      children: [
        SizedBox(
          width: size.width * 0.42,
          height: double.infinity,
          child: _buildBgImage(imagePath: page.imagePath),
        ),
        Expanded(
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(28, 28, 28, controlsReserve),
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

  /// Tablet: wider image panel left, scrollable card right.
  Widget _buildSplitCardTablet(
    BuildContext context,
    OnboardingPageData page,
    Size size,
    int index,
    int totalPages,
  ) {
    final isLandscape = size.width > size.height;
    final leftFraction = isLandscape ? 0.44 : 0.40;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final controlsReserve = 110.0 + safeBottom;

    return Row(
      children: [
        SizedBox(
          width: size.width * leftFraction,
          height: double.infinity,
          child: _buildBgImage(imagePath: page.imagePath),
        ),
        Expanded(
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(40)),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(40, 40, 40, controlsReserve),
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

  // ── build ──────────────────────────────────────────────────────────────────

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
            // ── 1. PageView ──────────────────────────────────────────────
            BlocBuilder<OnboardingBloc, OnboardingState>(
              builder: (context, state) {
                if (state is OnboardingLoaded) {
                  return PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: state.totalPages,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return isTablet
                          ? _buildSplitCardTablet(
                              context, page, size, index, state.totalPages)
                          : isPhoneLandscape
                              ? _buildSplitCardLandscape(
                                  context, page, size, index, state.totalPages)
                              : _buildSplitCardPortrait(
                                  context, page, size, index, state.totalPages);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // ── 2. Skip button ───────────────────────────────────────────
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
                            foregroundColor:
                                Colors.white.withValues(alpha: 0.85),
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

            // ── 3. Bottom controls ───────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BlocBuilder<OnboardingBloc, OnboardingState>(
                builder: (context, state) {
                  if (state is! OnboardingLoaded) return const SizedBox.shrink();

                  final leftInset = (!isTablet && !isPhoneLandscape)
                      ? 0.0
                      : isTablet
                          ? size.width *
                              (size.width > size.height ? 0.44 : 0.40)
                          : size.width * 0.42;

                  return _buildBottomControls(
                    context,
                    state,
                    leftInset,
                    controlsPadH,
                    controlsPadB,
                    isTablet,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sorry we are facing an issue')),
        );
      } else {
        log('not mounted');
      }
    }
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