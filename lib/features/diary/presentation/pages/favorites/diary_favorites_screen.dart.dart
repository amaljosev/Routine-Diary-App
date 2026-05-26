import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:routine/core/theme/theme_extenstions.dart';
import 'package:routine/core/utils/diary_color_parser.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/pages/preview/diary_preview.dart';

class DiaryFavoritesScreen extends StatefulWidget {
  const DiaryFavoritesScreen({super.key});

  @override
  State<DiaryFavoritesScreen> createState() => _DiaryFavoritesScreenState();
}

class _DiaryFavoritesScreenState extends State<DiaryFavoritesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DiaryBloc>().add(FetchFavoriteEntries());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<DiaryBloc, DiaryState>(
        buildWhen: (p, c) =>
            p.favoriteEntries != c.favoriteEntries ||
            p.isLoading != c.isLoading,
        builder: (context, state) {
          return Stack(
            children: [
              // ── Parallax background ──────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  Theme.of(context)
                          .extension<BackgroundImageTheme>()
                          ?.imagePath ??
                      'assets/img/themes/theme_1.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                ),
              ),

              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header ────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(CupertinoIcons.back),
                            ),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Favourites',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${state.favoriteEntries.length} cherished '
                                  '${state.favoriteEntries.length == 1 ? 'memory' : 'memories'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    Colors.redAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ── Loading / empty / list ─────────────────────────
                    if (state.isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.favoriteEntries.isEmpty)
                      SliverFillRemaining(
                        child: _EmptyFavoritesView(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _FavoriteEntryCard(
                              entry: state.favoriteEntries[index],
                              index: index,
                            ),
                            childCount: state.favoriteEntries.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyFavoritesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.favorite_border,
              size: 56,
              color: Colors.redAccent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No favourites yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap ♡ on any diary entry\nto save it here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Entry card ───────────────────────────────────────────────────────────────

class _FavoriteEntryCard extends StatelessWidget {
  final DiaryEntryModel entry;
  final int index;

  const _FavoriteEntryCard({required this.entry, required this.index});

  Color? _bgColor(BuildContext context) =>
      parseDiaryColor(entry.bgColor) ?? Theme.of(context).cardColor;

  ImageProvider? _bgImage() {
    if (entry.bgGalleryImagePath?.isNotEmpty == true) {
      final f = File(entry.bgGalleryImagePath!);
      if (f.existsSync()) return FileImage(f);
    }
    if (entry.bgLocalPath?.isNotEmpty == true) {
      final f = File(entry.bgLocalPath!);
      if (f.existsSync()) return FileImage(f);
    }
    if (entry.bgImagePath?.isNotEmpty == true) {
      return entry.bgImagePath!.startsWith('http')
          ? NetworkImage(entry.bgImagePath!)
          : AssetImage(entry.bgImagePath!) as ImageProvider;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = _bgImage();
    final color = _bgColor(context);
    final date = DateTime.tryParse(entry.date) ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DiaryPreviewScreen(entryId: entry.id),
            ),
          );
        },
        child: Hero(
          tag: 'favCard${entry.id}',
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: color,
                image: bg != null
                    ? DecorationImage(image: bg, fit: BoxFit.cover)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Scrim
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withValues(alpha: bg != null ? 0.45 : 0.0),
                            Colors.black.withValues(alpha: bg != null ? 0.65 : 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top row ─────────────────────────────────
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                intl.DateFormat('dd MMM yyyy').format(date),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: bg != null
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Mood
                            Text(
                              entry.mood.isEmpty ? '😊' : entry.mood,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 8),
                            // Unfav button
                            GestureDetector(
                              onTap: () {
                                context.read<DiaryBloc>().add(
                                  ToggleFavorite(
                                    id: entry.id,
                                    isFavorite: false,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // ── Title ────────────────────────────────────
                        Text(
                          entry.title.isEmpty ? 'Untitled' : entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFamily: entry.fontFamily,
                            color: bg != null
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.preview.isEmpty ? 'No content' : entry.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: bg != null
                                ? Colors.white.withValues(alpha: 0.75)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}