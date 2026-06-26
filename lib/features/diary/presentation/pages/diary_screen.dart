// lib/core/theme/app_theme.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/diary/presentation/blocs/cubit/showcase_cubit.dart';
import 'package:routine/features/diary/presentation/widgets/subscription_banner_widget.dart';
import 'package:routine/features/settings/presentation/pages/theme/theme_image_helper.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:routine/core/theme/theme_extenstions.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/pages/entry/diary_entry.dart';
import 'package:routine/features/diary/presentation/pages/history/history_screen.dart';
import 'package:routine/features/diary/presentation/widgets/bottom_nav_bar.dart';
import 'package:routine/features/diary/presentation/widgets/entry_card_widget.dart';
import 'package:routine/features/settings/presentation/pages/settings_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ShowcaseCubit, ShowcaseState>(
      listener: (_, state) {
        if (state.shouldShow == true) {
          Future.delayed(const Duration(milliseconds: 400), _startShowcase);
        }
      },
      child: Scaffold(
        // Let content slide behind the status bar so the hero image fills edge-to-edge
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // ── Single scrollable column ──────────────────────────────────
            CustomScrollView(
              slivers: [
                // 1. Hero image app bar
                SliverAppBar(
                  expandedHeight: 200.0,
                  pinned: true,
                  stretch: true,
                  backgroundColor: theme.colorScheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.blurBackground],
                    background: ThemeImageHelper.buildImage(
                      Theme.of(
                            context,
                          ).extension<BackgroundImageTheme>()?.imagePath ??
                          'assets/img/themes/theme_1.webp',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // 2. Subscription status banner
                const SliverToBoxAdapter(child: SubscriptionStatusBanner()),

                // 3. "Recent Entries" header + date chip
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: Text(
                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                // 4. Diary entries (loading / error / list / empty)
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
                                'Sorry there is a technical glitch at the'
                                ' moment, please try again later',
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
                        child: Center(
                          child: Text(
                            'No entries yet',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
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

                // 5. "View All" button — only when entries >= 10
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

                // 6. Bottom padding so last card clears the nav bar
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),

            // ── Bottom nav bar — stays on top, outside the scroll ─────────
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
                onFabTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DiaryEntryScreen(entry: null),
                    ),
                  );
                  if (result == true && context.mounted) {
                    context.read<DiaryBloc>().add(LoadDiaryEntries());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
