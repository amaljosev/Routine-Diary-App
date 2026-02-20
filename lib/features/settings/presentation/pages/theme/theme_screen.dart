import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/theme/app_colors.dart';
import 'package:routine/features/settings/presentation/bloc/apptheme_bloc.dart';

class ThemeSwitcherScreen extends StatefulWidget {
  const ThemeSwitcherScreen({super.key});

  @override
  State<ThemeSwitcherScreen> createState() => _ThemeSwitcherScreenState();
}

class _ThemeSwitcherScreenState extends State<ThemeSwitcherScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  final List<String> _themes = [
    'assets/img/themes/theme_1.png',
    'assets/img/themes/theme_2.jpg',
    'assets/img/themes/theme_3.png',
    'assets/img/themes/theme_7.png', 
    'assets/img/themes/theme_4.jpg',
    'assets/img/themes/theme_5.jpg',
    'assets/img/themes/theme_6.jpg',
  ];

  // Helper to get background color for preview based on index
  Color _getPreviewBackgroundColor(int index) {
    switch (index) {
      case 0:
        return AppColors.light1Background;
      case 1:
        return AppColors.light2Background;
      case 2:
        return AppColors.light3Background;
      case 3:
        return AppColors.light4Background; // Orange theme background
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

  // Get primary color for a given theme index
  Color _getThemePrimaryColor(int index) {
    switch (index) {
      case 0:
        return AppColors.light1Primary;
      case 1:
        return AppColors.light2Primary;
      case 2:
        return AppColors.light3Primary;
      case 3:
        return AppColors.light4Primary; // Orange theme primary
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

  // Get secondary color for a given theme index
  Color _getThemeSecondaryColor(int index) {
    switch (index) {
      case 0:
        return AppColors.light1Secondary;
      case 1:
        return AppColors.light2Secondary;
      case 2:
        return AppColors.light3Secondary;
      case 3:
        return AppColors.light4Secondary; // Orange theme secondary (Purple)
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

  // Get surface color for a given theme index
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

  // Determine if the theme at given index is dark (indices 4-6 are dark)
  bool _isPreviewDark(int index) => index >= 4;

  @override
  void initState() {
    super.initState();
    context.read<ThemeBloc>().add(LoadSavedTheme());

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final selectedThemeIndex = state.themeIndex;
        final previewPrimary = _getThemePrimaryColor(_currentPage);
        final previewSecondary = _getThemeSecondaryColor(_currentPage);

        return Scaffold(
          backgroundColor: _getPreviewBackgroundColor(_currentPage),
          appBar: AppBar(
            title: const Text('Choose Your Diary Theme'),
            titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: previewPrimary,
              fontWeight: FontWeight.bold,
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: previewPrimary,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              children: [
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
                          itemBuilder: (context, index) {
                            final isDarkPreview = _isPreviewDark(index);
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
                                scale: _currentPage == index ? 1.0 : 0.9,
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<ThemeBloc>().add(
                                      ChangeTheme(_currentPage),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _getThemeName(_currentPage),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        backgroundColor: previewPrimary,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),

                                      color: isDarkPreview
                                          ? Colors.white10
                                          : Colors.black12,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: Stack(
                                        children: [
                                          Column(
                                            children: [
                                              // Theme preview image
                                              Image.asset(
                                                _themes[index],
                                                width: double.infinity,
                                                height: 150,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: double.infinity,
                                                    height: 150,
                                                    color: _getThemePrimaryColor(index).withValues(alpha: 0.3),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.image_not_supported,
                                                        color: _getThemePrimaryColor(index),
                                                        size: 40,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              Expanded(
                                                child: ListView.builder(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  itemCount: 4,
                                                  itemBuilder: (context, idx) =>
                                                      _buildPreviewItem(
                                                        context,
                                                        index,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Border for the selected (saved) theme – use its own primary color
                                          if (selectedThemeIndex == index)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(32),
                                                  border: Border.all(
                                                    color:
                                                        _getThemePrimaryColor(
                                                          selectedThemeIndex,
                                                        ),
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
                        // Page indicator dots – use previewed theme's colors
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
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
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<ThemeBloc>().add(
                                ChangeTheme(_currentPage),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _getThemeName(_currentPage),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor: previewPrimary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: previewPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 5,
                              shadowColor: previewPrimary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            child: const Text(
                              'Use It',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Get friendly theme name for snackbar
  String _getThemeName(int index) {
    switch (index) {
      case 0:
        return 'Purple Teal Theme selected!';
      case 1:
        return 'Blue Orange Theme selected!';
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

  /// Builds a single preview item inside the theme card.
  /// [themeIndex] is the index of the theme this preview belongs to.
  Widget _buildPreviewItem(BuildContext context, int themeIndex) {
    final isDarkPreview = _isPreviewDark(themeIndex);
    final surfaceColor = _getThemeSurfaceColor(themeIndex);
    final primaryColor = _getThemePrimaryColor(themeIndex);

    // Define grayscale colors based on preview brightness
    final List<Color> gradientColors = isDarkPreview
        ? [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!]
        : [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        // Use previewed theme's surface color for the card background
        color: isDarkPreview
            ? surfaceColor.withValues(alpha: 0.6)
            : surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(
            alpha: 0.1,
          ), // Use previewed theme's primary
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkPreview
                ? Colors.black.withValues(alpha: 0.3)
                : primaryColor.withValues(
                    alpha: 0.08,
                  ), // Use previewed theme's primary
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
            // Left avatar placeholder
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
                  // First line: circle + line
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
                  // Second line: full width bar
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
                  // Third line: half width bar
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
                  // Fourth line: small circle + short bar
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
}