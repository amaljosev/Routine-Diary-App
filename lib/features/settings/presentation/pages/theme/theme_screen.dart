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

  // ── navigation ────────────────────────────────────────────────────────────

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

  void _restoreCustomTheme() {
    final isPremium = context.read<PremiumBloc>().state.isPremium;
    final customModel = context.read<ThemeBloc>().state.customThemeModel;
    if (customModel == null) return;

    void apply() {
      context.read<ThemeBloc>().add(ApplyCustomTheme(customModel));
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

    final List<Color> gc = isDarkPreview
        ? [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!]
        : [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!];

    BoxDecoration bar(double h) => BoxDecoration(
      borderRadius: BorderRadius.circular(3),
      gradient: LinearGradient(
        colors: gc,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkPreview
            ? surfaceColor.withValues(alpha: 0.6)
            : surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
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
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: gc,
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: gc,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(height: 18, decoration: bar(18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: bar(12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.5,
                    decoration: bar(12),
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
                            colors: gc,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(width: 50, height: 12, decoration: bar(12)),
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
        final int selectedThemeIndex = themeState.isCustomThemeActive
            ? -1
            : themeState.themeIndex;
        final bool isCustomActive = themeState.isCustomThemeActive;

        if (!_initialScrollDone) {
          _isLoading = false;
          final int jumpTo = themeState.isCustomThemeActive
              ? 0
              : themeState.themeIndex;
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

        final Color previewPrimary = _getThemePrimaryColor(_currentPage);
        final Color previewSecondary = _getThemeSecondaryColor(_currentPage);
        final bool isCurrentPageSelected = selectedThemeIndex == _currentPage;
        final bool isDarkBg = _isPreviewDark(_currentPage);

        return BlocBuilder<PremiumBloc, PremiumState>(
          builder: (context, premiumState) {
            final bool showRestoreButton =
                premiumState.wasEverSubscriber &&
                themeState.customThemeModel != null &&
                !isCustomActive;

            return Scaffold(
              backgroundColor: _getPreviewBackgroundColor(_currentPage),
              appBar: AppBar(
                title: const Text('Choose Your Diary Theme'),
                titleTextStyle: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(
                      color: previewPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                foregroundColor: previewPrimary,
                elevation: 0,
              ),
              body: Column(
                children: [
                  // ── PageView carousel ─────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: _themes.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (context, index) {
                              final bool isDarkPreview = _isPreviewDark(index);
                              final bool isSelected =
                                  selectedThemeIndex == index;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                margin: EdgeInsets.only(
                                  top: _currentPage == index ? 0 : 20,
                                  bottom: _currentPage == index ? 0 : 10,
                                  left: 10,
                                  right: 10,
                                ),
                                child: Transform.scale(
                                  scale: _currentPage == index ? 1.0 : 0.9,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selectedThemeIndex != index) {
                                        context.read<ThemeBloc>().add(
                                          ChangeTheme(index),
                                        );
                                        _pageController.animateToPage(
                                          index,
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          curve: Curves.easeInOutCubic,
                                        );
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: isDarkPreview
                                            ? Colors.white10
                                            : Colors.black12,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Stack(
                                          children: [
                                            Column(
                                              children: [
                                                Image.asset(
                                                  _themes[index],
                                                  width: double.infinity,
                                                  height: 150,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (ctx, err, _) =>
                                                      Container(
                                                        width: double.infinity,
                                                        height: 150,
                                                        color:
                                                            _getThemePrimaryColor(
                                                              index,
                                                            ).withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        child: Center(
                                                          child: Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            color:
                                                                _getThemePrimaryColor(
                                                                  index,
                                                                ),
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
                                                        const EdgeInsets.all(8),
                                                    itemCount: 4,
                                                    itemBuilder: (ctx, idx) =>
                                                        _buildPreviewItem(
                                                          context,
                                                          index,
                                                        ),
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
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          _getThemePrimaryColor(
                                                            index,
                                                          ),
                                                      width: 2,
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
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom action area ────────────────────────────────────
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 10,
                        children: [
                          // Page indicator dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _themes.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 6,
                                width: _currentPage == index ? 24 : 6,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? previewPrimary
                                      : previewSecondary.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),

                          _SelectThemeButton(
                            isSelected: isCurrentPageSelected,
                            primaryColor: previewPrimary,
                            isDarkBackground: isDarkBg,
                            label: isCurrentPageSelected
                                ? 'Currently Selected'
                                : 'Use This Theme',
                            onTap: isCurrentPageSelected
                                ? null
                                : () => context.read<ThemeBloc>().add(
                                    ChangeTheme(_currentPage),
                                  ),
                          ),

                          // Second row: Customize | Restore (side by side)
                          Row(
                            children: [
                              Expanded(
                                child: _CustomizeThemeFAB(
                                  isActive: isCustomActive,
                                  primaryColor: previewPrimary,
                                  isDarkBackground: isDarkBg,
                                  onTap: _openCustomThemeEditor,
                                ),
                              ),
                              if (showRestoreButton) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _RestoreCustomThemeButton(
                                    primaryColor: previewPrimary,
                                    isDarkBackground: isDarkBg,
                                    isPremium: premiumState.isPremium,
                                    onTap: _restoreCustomTheme,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Use This Theme" / "Currently Selected" button
// ─────────────────────────────────────────────────────────────────────────────

class _SelectThemeButton extends StatelessWidget {
  final bool isSelected;
  final Color primaryColor;
  final bool isDarkBackground;
  final String label;
  final VoidCallback? onTap;

  const _SelectThemeButton({
    required this.isSelected,
    required this.primaryColor,
    required this.isDarkBackground,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      // Frosted "Currently Selected" chip
      return Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: isDarkBackground ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    // Solid filled "Use This Theme" pill
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Restore Custom Theme" button  (secondary / ghost)
// ─────────────────────────────────────────────────────────────────────────────

class _RestoreCustomThemeButton extends StatelessWidget {
  final Color primaryColor;
  final bool isDarkBackground;
  final bool isPremium;
  final VoidCallback onTap;

  const _RestoreCustomThemeButton({
    required this.primaryColor,
    required this.isDarkBackground,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            color: primaryColor.withValues(
              alpha: isDarkBackground ? 0.12 : 0.08,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.30),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPremium ? Icons.history_rounded : Icons.lock_open_rounded,
                size: 17,
                color: primaryColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Restore Theme',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Customize Theme" FAB pill
// ─────────────────────────────────────────────────────────────────────────────

class _CustomizeThemeFAB extends StatelessWidget {
  final bool isActive;
  final Color primaryColor;
  final bool isDarkBackground;
  final VoidCallback onTap;

  const _CustomizeThemeFAB({
    required this.isActive,
    required this.primaryColor,
    required this.isDarkBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          color: isActive
              ? primaryColor
              : (isDarkBackground
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.72)),
          border: Border.all(
            color: isActive
                ? primaryColor
                : primaryColor.withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: isActive ? 0.38 : 0.15),
              blurRadius: isActive ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: isActive ? Colors.white : primaryColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Customize Theme',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isActive ? Colors.white : primaryColor,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: primaryColor.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
