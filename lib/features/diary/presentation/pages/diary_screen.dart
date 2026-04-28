import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/diary/presentation/blocs/cubit/showcase_cubit.dart';
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

// ---------------------------------------------------------------------------
// StatefulWidget — owns GlobalKeys and wires ShowcaseView v5 lifecycle
// ---------------------------------------------------------------------------

class _DiaryBody extends StatefulWidget {
  const _DiaryBody();

  @override
  State<_DiaryBody> createState() => _DiaryBodyState();
}

class _DiaryBodyState extends State<_DiaryBody> {
  // One GlobalKey per item you want to highlight.
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();

  // A fixed scope name — must be unique per screen if you have multiple.
  static const _scope = 'diary_home_showcase';

  @override
  void initState() {
    super.initState();

    // ── v5 API: register this screen's showcase scope ──────────────────────
    ShowcaseView.register(
      scope: _scope,
      onFinish: () {
        if (mounted) context.read<ShowcaseCubit>().markHomeSeen();
      },
    );

    // Check SharedPrefs after first frame and emit shouldShow.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShowcaseCubit>().checkIfShouldShowHome();
    });
  }

  void _startShowcase() {
    // ── v5 API: retrieve the registered scope and start ────────────────────
    ShowcaseView.getNamed(_scope).startShowCase([
      _fabKey,
      _calendarKey,
      _settingsKey,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // BlocListener reacts to the cubit emitting shouldShow = true.
    return BlocListener<ShowcaseCubit, ShowcaseState>(
      listener: (_, state) {
        if (state.shouldShow == true) {
          Future.delayed(
            const Duration(milliseconds: 400),
            _startShowcase,
          );
        }
      },
      child: Scaffold(
        body: Stack(
          alignment: AlignmentGeometry.bottomCenter,
          children: [
            // ── Background SliverAppBar layer ───────────────────────────────
            CustomScrollView(
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  stretch: true,
                  backgroundColor: theme.colorScheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.blurBackground],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          Theme.of(context)
                                  .extension<BackgroundImageTheme>()
                                  ?.imagePath ??
                              'assets/img/themes/theme_1.webp', // ← updated fallback
                          fit: BoxFit.cover,
                          filterQuality:  FilterQuality.high,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Scrollable content layer ────────────────────────────────────
            CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 170)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: Row(
                      children: [
                        Text(
                          "Recent Entries",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Sorry there is a technical glitch at the"
                                " moment, please try again later",
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

                    final allEntries =
                        List<DiaryEntryModel>.from(state.entries);
                    allEntries.sort((a, b) {
                      final dateA = DateTime.tryParse(a.date) ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final dateB = DateTime.tryParse(b.date) ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      return dateB.compareTo(dateA);
                    });

                    final latestEntries = allEntries.take(30).toList();

                    if (latestEntries.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text(
                            "No entries yet",
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

                BlocBuilder<DiaryBloc, DiaryState>(
                  builder: (context, state) {
                    if (state.entries.length >= 10) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
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
                                    horizontal: 24, vertical: 12),
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

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),

            // ── Bottom nav — keys injected for Showcase wrapping ────────────
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
                      builder: (_) => const DiaryCalendarScreen()),
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