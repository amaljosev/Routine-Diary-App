// lib/features/settings/presentation/pages/theme/theme_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/theme/app_colors.dart';
import 'package:routine/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:routine/features/premium/presentation/widgets/paywall_sheet.dart';
import 'package:routine/features/settings/presentation/bloc/apptheme_bloc.dart';
import 'package:routine/features/settings/presentation/pages/theme/custom_theme_screen.dart';

class ThemeSwitcherScreen extends StatefulWidget {
  const ThemeSwitcherScreen({super.key});
  @override
  State<ThemeSwitcherScreen> createState() => _ThemeSwitcherScreenState();
}

class _ThemeSwitcherScreenState extends State<ThemeSwitcherScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _initialScrollDone = false;
  bool _isLoading = true;

  // Only built-in themes — no sentinel needed anymore.
  final List<String> _themes = [
    'assets/img/themes/theme_2.webp',
    'assets/img/themes/theme_1.webp',
    'assets/img/themes/theme_3.webp',
    'assets/img/themes/theme_7.webp',
    'assets/img/themes/theme_4.webp',
    'assets/img/themes/theme_5.webp',
    'assets/img/themes/theme_6.webp',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.80);
    context.read<ThemeBloc>().add(LoadSavedTheme());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── color helpers ─────────────────────────────────────────────────────────

  Color _getPreviewBackgroundColor(int index) {
    switch (index) {
      case 0:
        return AppColors.light1Background;
      case 1:
        return AppColors.light2Background;
      case 2:
        return AppColors.light3Background;
      case 3:
        return AppColors.light4Background;
      case 4:
        return AppColors.dark1Background;
      case 5:
        return AppColors.dark2Background;
      case 6:
        return AppColors.dark3Background;
      default:
        return Theme.of(context).scaffoldBackgroundColor;
    }
  }

  Color _getThemePrimaryColor(int index) {
    switch (index) {
      case 0:
        return AppColors.light1Primary;
      case 1:
        return AppColors.light2Primary;
      case 2:
        return AppColors.light3Primary;
      case 3:
        return AppColors.light4Primary;
      case 4:
        return AppColors.dark1Primary;
      case 5:
        return AppColors.dark2Primary;
      case 6:
        return AppColors.dark3Primary;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getThemeSecondaryColor(int index) {
    switch (index) {
      case 0:
        return AppColors.light1Secondary;
      case 1:
        return AppColors.light2Secondary;
      case 2:
        return AppColors.light3Secondary;
      case 3:
        return AppColors.light4Secondary;
      case 4:
        return AppColors.dark1Secondary;
      case 5:
        return AppColors.dark2Secondary;
      case 6:
        return AppColors.dark3Secondary;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  Color _getThemeSurfaceColor(int index) {
    switch (index) {
      case 0:
        return AppColors.light1Surface;
      case 1:
        return AppColors.light2Surface;
      case 2:
        return AppColors.light3Surface;
      case 3:
        return AppColors.light4Surface;
      case 4:
        return AppColors.dark1Surface;
      case 5:
        return AppColors.dark2Surface;
      case 6:
        return AppColors.dark3Surface;
      default:
        return Theme.of(context).colorScheme.surface;
    }
  }

  bool _isPreviewDark(int index) => index >= 4;

  String _getThemeName(int index) {
    switch (index) {
      case 0:
        return 'Blue Orange Theme selected!';
      case 1:
        return 'Purple Teal Theme selected!';
      case 2:
        return 'Green Coral Theme selected!';
      case 3:
        return 'Orange Purple Theme selected!';
      case 4:
        return 'Deep Purple Amber Theme selected!';
      case 5:
        return 'Blue Grey Theme selected!';
      case 6:
        return 'Forest Green Theme selected!';
      default:
        return 'Theme ${index + 1} selected!';
    }
  }

  // ── navigation to Custom Theme editor ────────────────────────────────────

  void _openCustomThemeEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<ThemeBloc>()),
            BlocProvider.value(value: context.read<PremiumBloc>()),
          ],
          child: const CustomThemeScreen(),
        ),
      ),
    );
  }

  // ── restore custom theme ──────────────────────────────────────────────────
  //
  // Called when the user taps "Restore Custom Theme".
  // If already premium  → apply immediately.
  // If not subscribed   → show paywall; apply on success.

  void _restoreCustomTheme() {
    final isPremium = context.read<PremiumBloc>().state.isPremium;
    final customModel = context.read<ThemeBloc>().state.customThemeModel;
    if (customModel == null) return;

    void apply() {
      context.read<ThemeBloc>().add(ApplyCustomTheme(customModel));
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Custom theme restored!'),
          backgroundColor: _getThemePrimaryColor(_currentPage),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }

    if (isPremium) {
      apply();
    } else {
      showPaywallSheet(context, onSuccess: apply);
    }
  }

  // ── preview card skeleton ─────────────────────────────────────────────────

  Widget _buildPreviewItem(BuildContext context, int themeIndex) {
    final isDarkPreview = _isPreviewDark(themeIndex);
    final surfaceColor = _getThemeSurfaceColor(themeIndex);
    final primaryColor = _getThemePrimaryColor(themeIndex);

    final List<Color> gradientColors = isDarkPreview
        ? [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!]
        : [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkPreview
            ? surfaceColor.withValues(alpha: 0.6)
            : surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkPreview
                ? Colors.black.withValues(alpha: 0.3)
                : primaryColor.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: gradientColors,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: gradientColors,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: gradientColors,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 50,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: gradientColors,
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
    );
  }

  // ── main build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        // When custom theme is active we don't highlight any built-in page.
        final int selectedThemeIndex =
            themeState.isCustomThemeActive ? -1 : themeState.themeIndex;
        final bool isCustomActive = themeState.isCustomThemeActive;

        if (!_initialScrollDone) {
          _isLoading = false;
          final jumpTo =
              themeState.isCustomThemeActive ? 0 : themeState.themeIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            void doJump() {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(jumpTo);
                setState(() {
                  _currentPage = jumpTo;
                  _initialScrollDone = true;
                });
              } else {
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mounted) doJump();
                });
              }
            }

            doJump();
          });
        }

        if (_isLoading) {
          return Scaffold(
            backgroundColor: AppColors.light1Background,
            appBar: AppBar(
              title: const Text('Choose Your Diary Theme'),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.light1Primary,
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final previewPrimary = _getThemePrimaryColor(_currentPage);
        final previewSecondary = _getThemeSecondaryColor(_currentPage);
        final isCurrentPageSelected = selectedThemeIndex == _currentPage;

        return BlocBuilder<PremiumBloc, PremiumState>(
          builder: (context, premiumState) {
            // ── Restore button visibility logic ─────────────────────────────
            //
            // Show when ALL of:
            //   • user was ever a subscriber (lapsed, not a stranger)
            //   • a saved custom theme config exists (something to restore)
            //   • custom theme is NOT already the active theme
            //
            // Hidden when:
            //   • user is currently subscribed + custom theme active
            //     (they're already enjoying it — no restore needed)
            //   • user never subscribed (they haven't created a theme yet)
            //   • no saved theme data exists
            final bool showRestoreButton = premiumState.wasEverSubscriber &&
                themeState.customThemeModel != null &&
                !isCustomActive;

            return Scaffold(
              backgroundColor: _getPreviewBackgroundColor(_currentPage),

              appBar: AppBar(
                title: const Text('Choose Your Diary Theme'),
                titleTextStyle:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: previewPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                foregroundColor: previewPrimary,
                elevation: 0,
              ),

              // ── Persistent "Customize Theme" pill ────────────────────────
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _CustomizeThemePill(
                  isActive: isCustomActive,
                  primaryColor: previewPrimary,
                  onTap: _openCustomThemeEditor,
                ),
              ),

              body: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    // ── Page view ───────────────────────────────────────────
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: _themes.length,
                              onPageChanged: (index) =>
                                  setState(() => _currentPage = index),
                              itemBuilder: (context, index) {
                                final isDarkPreview = _isPreviewDark(index);
                                final isSelected =
                                    selectedThemeIndex == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  margin: EdgeInsets.only(
                                    top: _currentPage == index ? 0 : 20,
                                    bottom: _currentPage == index ? 0 : 10,
                                    right: 10,
                                    left: 10,
                                  ),
                                  child: Transform.scale(
                                    scale:
                                        _currentPage == index ? 1.0 : 0.9,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (selectedThemeIndex != index) {
                                          context.read<ThemeBloc>().add(
                                                ChangeTheme(index),
                                              );
                                          _pageController.animateToPage(
                                            index,
                                            duration: const Duration(
                                                milliseconds: 400),
                                            curve: Curves.easeInOutCubic,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                _getThemeName(index),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              backgroundColor:
                                                  _getThemePrimaryColor(
                                                      index),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(32),
                                          color: isDarkPreview
                                              ? Colors.white10
                                              : Colors.black12,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(32),
                                          child: Stack(
                                            children: [
                                              Column(
                                                children: [
                                                  Image.asset(
                                                    _themes[index],
                                                    width: double.infinity,
                                                    height: 150,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                            error, _) =>
                                                        Container(
                                                      width: double.infinity,
                                                      height: 150,
                                                      color:
                                                          _getThemePrimaryColor(
                                                                  index)
                                                              .withValues(
                                                                  alpha: 0.3),
                                                      child: Center(
                                                        child: Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          color:
                                                              _getThemePrimaryColor(
                                                                  index),
                                                          size: 40,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: ListView.builder(
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      itemCount: 4,
                                                      itemBuilder:
                                                          (context, idx) =>
                                                              _buildPreviewItem(
                                                                  context,
                                                                  index),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (isSelected)
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              32),
                                                      border: Border.all(
                                                        color:
                                                            _getThemePrimaryColor(
                                                                index),
                                                        width: 4,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Page indicator dots
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _themes.length,
                                  (index) => AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    height: 6,
                                    width:
                                        _currentPage == index ? 24 : 6,
                                    decoration: BoxDecoration(
                                      color: _currentPage == index
                                          ? previewPrimary
                                          : previewSecondary.withValues(
                                              alpha: 0.3),
                                      borderRadius:
                                          BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Bottom button area ────────────────────────────────
                    SafeArea(
                      child: Padding(
                        // Extra bottom padding so the FAB pill doesn't overlap
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 72),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── "Currently Selected" badge ────────────────
                            if (isCurrentPageSelected)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: previewPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '✓ Current Theme',
                                  style: TextStyle(
                                    color: previewPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // ── "Use This Theme" button ───────────────────
                            ElevatedButton(
                              onPressed: isCurrentPageSelected
                                  ? null
                                  : () {
                                      context
                                          .read<ThemeBloc>()
                                          .add(ChangeTheme(_currentPage));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _getThemeName(_currentPage),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                          backgroundColor: previewPrimary,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: previewPrimary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    previewPrimary.withValues(alpha: 0.3),
                                disabledForegroundColor:
                                    Colors.white.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                elevation: isCurrentPageSelected ? 0 : 5,
                                minimumSize:
                                    const Size(double.infinity, 50),
                              ),
                              child: Text(
                                isCurrentPageSelected
                                    ? 'Currently Selected'
                                    : 'Use This Theme',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),

                            // ── "Restore Custom Theme" button ─────────────
                            //
                            // Visible only to lapsed subscribers who have a
                            // saved custom theme that is not currently active.
                            if (showRestoreButton) ...[
                              const SizedBox(height: 12),
                              _RestoreCustomThemeButton(
                                primaryColor: previewPrimary,
                                isPremium: premiumState.isPremium,
                                onTap: _restoreCustomTheme,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Restore Custom Theme button
// ─────────────────────────────────────────────────────────────────────────────

class _RestoreCustomThemeButton extends StatelessWidget {
  final Color primaryColor;
  final bool isPremium;
  final VoidCallback onTap;

  const _RestoreCustomThemeButton({
    required this.primaryColor,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          isPremium ? Icons.palette_outlined : Icons.lock_open_outlined,
          size: 18,
          color: primaryColor,
        ),
        label: Text(
          'Restore Custom Theme',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: primaryColor,
            letterSpacing: 0.3,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primaryColor, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Persistent "Customize Theme" pill button
// ─────────────────────────────────────────────────────────────────────────────

class _CustomizeThemePill extends StatelessWidget {
  final bool isActive;
  final Color primaryColor;
  final VoidCallback onTap;

  const _CustomizeThemePill({
    required this.isActive,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: isActive ? primaryColor : Colors.transparent,
          border: Border.all(color: primaryColor, width: 2),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette_outlined,
              size: 20,
              color: isActive ? Colors.white : primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Customize Theme',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isActive ? Colors.white : primaryColor,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}