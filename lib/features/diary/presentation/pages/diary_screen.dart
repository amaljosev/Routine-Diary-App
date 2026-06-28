// lib/features/diary/presentation/pages/diary_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/theme/theme_extenstions.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/presentation/blocs/cubit/showcase_cubit.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/pages/entry/diary_entry.dart';
import 'package:routine/features/diary/presentation/pages/history/history_screen.dart';
import 'package:routine/features/diary/presentation/widgets/bottom_nav_bar.dart';
import 'package:routine/features/diary/presentation/widgets/entry_card_widget.dart';
import 'package:routine/features/premium/presentation/widgets/subscription_banner_widget.dart';
import 'package:routine/features/settings/presentation/pages/settings_screen.dart';
import 'package:routine/features/settings/presentation/pages/theme/theme_image_helper.dart';
import 'package:showcaseview/showcaseview.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShowcaseCubit(),
      child: const _DiaryBody(),
    );
  }
}

class _DiaryBody extends StatefulWidget {
  const _DiaryBody();

  @override
  State<_DiaryBody> createState() => _DiaryBodyState();
}

class _DiaryBodyState extends State<_DiaryBody> {
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();

  static const _scope = 'diary_home_showcase';

  @override
  void initState() {
    super.initState();
    ShowcaseView.register(
      scope: _scope,
      onFinish: () {
        if (mounted) context.read<ShowcaseCubit>().markHomeSeen();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShowcaseCubit>().checkIfShouldShowHome();
    });
  }

  void _startShowcase() {
    ShowcaseView.getNamed(
      _scope,
    ).startShowCase([_fabKey, _calendarKey, _settingsKey]);
  }

  void _goToNewEntry() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DiaryEntryScreen(entry: null)),
    );
    if (result == true && mounted) {
      context.read<DiaryBloc>().add(LoadDiaryEntries());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgImagePath =
        theme.extension<BackgroundImageTheme>()?.imagePath ??
        'assets/img/themes/theme_1.webp';

    return BlocListener<ShowcaseCubit, ShowcaseState>(
      listener: (_, state) {
        if (state.shouldShow == true) {
          Future.delayed(const Duration(milliseconds: 400), _startShowcase);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // 1. Hero SliverAppBar
                SliverAppBar(
                  pinned: false,
                  expandedHeight: 200,
                  collapsedHeight: 60,
                  stretch: true,
                  stretchTriggerOffset: 100,
                  backgroundColor: theme.colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                       ((constraints.maxHeight - 60) / (200 - 60)).clamp(
                            0.0,  
                            1.0,
                          );

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image always fully visible — no Opacity wrapper
                          ThemeImageHelper.buildImage(
                            bgImagePath,
                            fit: BoxFit.cover,
                          ),

                          
                        ],
                      );
                    },
                  ),
                ),

                // 2. Subscription banner
                const SliverToBoxAdapter(child: SubscriptionStatusBanner(isHome: true,)),

                // 3. Entries / empty state
                BlocBuilder<DiaryBloc, DiaryState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (state.errorMessage != null) {
                      log(state.errorMessage.toString());
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sorry, there\'s a technical glitch right now.'
                                ' Please try again later.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                ),
                                child: const Text('Contact us'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final allEntries = List<DiaryEntryModel>.from(state.entries)
                      ..sort((a, b) {
                        final dateA =
                            DateTime.tryParse(a.date) ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        final dateB =
                            DateTime.tryParse(b.date) ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        return dateB.compareTo(dateA);
                      });

                    final latestEntries = allEntries.take(30).toList();

                    if (latestEntries.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyDiaryState(onWriteFirst: _goToNewEntry),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            DiaryEntryCard(entry: latestEntries[index]),
                        childCount: latestEntries.length,
                      ),
                    );
                  },
                ),

                // 4. "View All" button
                BlocBuilder<DiaryBloc, DiaryState>(
                  builder: (context, state) {
                    if (state.entries.length >= 10) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DiaryCalendarScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('View All Entries'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onPrimary,
                                backgroundColor: theme.colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),

                // 5. Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),

            // Bottom nav bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNav(
                fabKey: _fabKey,
                calendarKey: _calendarKey,
                settingsKey: _settingsKey,
                onCalendarTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DiaryCalendarScreen(),
                  ),
                ),
                onSettingsTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                onFabTap: _goToNewEntry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDiaryState extends StatefulWidget {
  const _EmptyDiaryState({required this.onWriteFirst});

  final VoidCallback onWriteFirst;

  @override
  State<_EmptyDiaryState> createState() => _EmptyDiaryStateState();
}

class _EmptyDiaryStateState extends State<_EmptyDiaryState>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final AnimationController _arrowController;

  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _iconScale;
  late final Animation<double> _pulse;
  late final Animation<double> _arrowBounce;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.9, curve: Curves.elasticOut),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _arrowBounce = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: widget.onWriteFirst,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 160),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end, // ← bottom aligned
          children: [
            // Card
            FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: ScaleTransition(
                        scale: _iconScale,
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, child) => Transform.scale(
                            scale: _pulse.value,
                            child: child,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outermost soft circle
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.06,
                                  ),
                                ),
                              ),

                              // Mid circle
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                ),
                              ),

                              // Inner circle — slightly more opaque
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      colorScheme.primary.withValues(
                                        alpha: 0.14,
                                      ),
                                      colorScheme.primary.withValues(
                                        alpha: 0.06,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Decorative top-left accent dot
                              Positioned(
                                top: 22,
                                left: 22,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.secondary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                              ),

                              // Decorative bottom-right accent dot
                              Positioned(
                                bottom: 28,
                                right: 20,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.tertiary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                              ),

                              // Decorative top-right small ring
                              Positioned(
                                top: 36,
                                right: 28,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),

                              // Decorative bottom-left small ring
                              Positioned(
                                bottom: 36,
                                left: 24,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.secondary.withValues(
                                        alpha: 0.25,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),

                              // The illustration on top
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: Image.asset('assets/img/empty.webp'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Begin with today',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No filters, no audience —\njust you and your thoughts.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouncing arrow
            FadeTransition(
              opacity: _fadeIn,
              child: AnimatedBuilder(
                animation: _arrowBounce,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _arrowBounce.value),
                  child: child,
                ),
                child: Column(
                  children: [
                    Text(
                      'or tap',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 28,
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
