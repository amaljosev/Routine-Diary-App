import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:routine/features/settings/presentation/bloc/apptheme_bloc.dart';

class ThemeSwitcherScreen extends StatefulWidget {
  const ThemeSwitcherScreen({super.key});

  @override
  State<ThemeSwitcherScreen> createState() => _ThemeSwitcherScreenState();
}

class _ThemeSwitcherScreenState extends State<ThemeSwitcherScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  // Map indices to asset images (0-5)
  final List<String> _themes = [
    'assets/img/themes/theme_1.png',
    'assets/img/themes/theme_2.png',
    'assets/img/themes/theme_3.png',
    'assets/img/themes/theme_1.png',
    'assets/img/themes/theme_2.png',
    'assets/img/themes/theme_3.png',
  ];

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final selectedThemeIndex = state.themeIndex;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Choose Your Diary Theme'),
            centerTitle: true,
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
                          onPageChanged: (index) {
                            // No need to set selectedThemeIndex here; it's handled by bloc on button press.
                          },
                          itemBuilder: (context, index) {
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
                                    // Just scroll to this theme; selection happens on button press.
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                          spreadRadius:
                                              _currentPage == index ? 2 : 0,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: Stack(
                                        children: [
                                          Column(
                                            children: [
                                              Image.asset(
                                                _themes[index],
                                                width: double.infinity,
                                                height: 150,
                                                fit: BoxFit.fitWidth,
                                              ),
                                              Expanded(
                                                child: ListView.builder(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  itemCount: 4,
                                                  itemBuilder:
                                                      (context, idx) =>
                                                          _buildPreviewItem(
                                                            context,
                                                            isDark,
                                                          ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (selectedThemeIndex == index)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(32),
                                                  border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
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
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                height: 6,
                                width: _currentPage == index ? 24 : 6,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withValues(alpha: 0.3),
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
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<ThemeBloc>().add(
                              ChangeTheme(_currentPage),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Theme ${_currentPage + 1} selected!',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                        shadowColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
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
        );
      },
    );
  }

  Widget _buildPreviewItem(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.6)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : theme.colorScheme.primary.withValues(alpha: 0.08),
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
                  colors: isDark
                      ? [
                          Colors.grey[800]!,
                          Colors.grey[700]!,
                          Colors.grey[800]!,
                        ]
                      : [
                          Colors.grey[300]!,
                          Colors.grey[100]!,
                          Colors.grey[300]!,
                        ],
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
                            colors: isDark
                                ? [
                                    Colors.grey[800]!,
                                    Colors.grey[700]!,
                                    Colors.grey[800]!,
                                  ]
                                : [
                                    Colors.grey[300]!,
                                    Colors.grey[100]!,
                                    Colors.grey[300]!,
                                  ],
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
                              colors: isDark
                                  ? [
                                      Colors.grey[800]!,
                                      Colors.grey[700]!,
                                      Colors.grey[800]!,
                                    ]
                                  : [
                                      Colors.grey[300]!,
                                      Colors.grey[100]!,
                                      Colors.grey[300]!,
                                    ],
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
                        colors: isDark
                            ? [
                                Colors.grey[800]!,
                                Colors.grey[700]!,
                                Colors.grey[800]!,
                              ]
                            : [
                                Colors.grey[300]!,
                                Colors.grey[100]!,
                                Colors.grey[300]!,
                              ],
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
                        colors: isDark
                            ? [
                                Colors.grey[800]!,
                                Colors.grey[700]!,
                                Colors.grey[800]!,
                              ]
                            : [
                                Colors.grey[300]!,
                                Colors.grey[100]!,
                                Colors.grey[300]!,
                              ],
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
                            colors: isDark
                                ? [
                                    Colors.grey[800]!,
                                    Colors.grey[700]!,
                                    Colors.grey[800]!,
                                  ]
                                : [
                                    Colors.grey[300]!,
                                    Colors.grey[100]!,
                                    Colors.grey[300]!,
                                  ],
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
                            colors: isDark
                                ? [
                                    Colors.grey[800]!,
                                    Colors.grey[700]!,
                                    Colors.grey[800]!,
                                  ]
                                : [
                                    Colors.grey[300]!,
                                    Colors.grey[100]!,
                                    Colors.grey[300]!,
                                  ],
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