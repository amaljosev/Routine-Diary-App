import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import 'package:routine/core/utils/diary_color_parser.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/domain/entities/sticker_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/blocs/diary_entry/diary_entry_bloc.dart';
import 'package:routine/features/diary/presentation/pages/entry/diary_entry.dart';
import 'package:routine/features/diary/presentation/widgets/delete_entry_dialog.dart';
import 'package:routine/features/diary/presentation/widgets/image_overlay.dart';
import 'package:routine/features/diary/presentation/widgets/sticker_overlay.dart';

// ============================================================
// ================== ENTRY POINT =============================
// ============================================================

class DiaryPreviewScreen extends StatelessWidget {
  final String entryId;

  const DiaryPreviewScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<DiaryBloc>()..add(FetchEntryById(entryId)),
      child: DiaryEntryPreviewForm(entryId: entryId),
    );
  }
}

// ============================================================
// ================== FORM ====================================
// ============================================================

class DiaryEntryPreviewForm extends StatefulWidget {
  final String entryId;

  const DiaryEntryPreviewForm({super.key, required this.entryId});

  @override
  State<DiaryEntryPreviewForm> createState() => _DiaryEntryPreviewFormState();
}

class _DiaryEntryPreviewFormState extends State<DiaryEntryPreviewForm> {
  final ScrollController _scrollController = ScrollController();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── JSON parsers ───────────────────────────────────────────────────────────

  List<StickerModel> _parseStickers(DiaryEntryModel entry) {
    try {
      if (entry.stickersJson == null || entry.stickersJson!.isEmpty) return [];
      return (List<Map<String, dynamic>>.from(jsonDecode(entry.stickersJson!)))
          .map((m) => StickerModel.fromJson(m))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<DiaryImage> _parseImages(DiaryEntryModel entry) {
    try {
      if (entry.imagesJson == null || entry.imagesJson!.isEmpty) return [];
      return (List<Map<String, dynamic>>.from(jsonDecode(entry.imagesJson!)))
          .map((m) => DiaryImage.fromJson(m))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Root ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) =>
          context.read<DiaryBloc>().add(LoadDiaryEntries()),
      child: Scaffold(
        body: BlocBuilder<DiaryBloc, DiaryState>(
          buildWhen: (p, c) =>
              c.entries.any((e) => e.id == widget.entryId) ||
              p.isLoading != c.isLoading ||
              p.errorMessage != c.errorMessage,
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.errorMessage != null) {
              return Center(
                child: Text(
                  'Please try again later',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }
            try {
              final entry =
                  state.entries.firstWhere((e) => e.id == widget.entryId);
              return _buildBackground(context, entry);
            } catch (_) {
              return Center(
                child: Text(
                  'Diary entry not found',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // ── Background — identical structure to entry screen ──────────────────────

  Widget _buildBackground(BuildContext context, DiaryEntryModel entry) {
    final theme = Theme.of(context);

    final backgroundColor =
        parseDiaryColor(entry.bgColor) ?? theme.scaffoldBackgroundColor;

    ImageProvider? backgroundImage;

    if (entry.bgGalleryImagePath != null &&
        entry.bgGalleryImagePath!.isNotEmpty) {
      final file = File(entry.bgGalleryImagePath!);
      if (file.existsSync()) backgroundImage = FileImage(file);
    } else if (entry.bgLocalPath != null && entry.bgLocalPath!.isNotEmpty) {
      final file = File(entry.bgLocalPath!);
      if (file.existsSync()) {
        backgroundImage = FileImage(file);
      } else if (entry.bgImagePath != null && entry.bgImagePath!.isNotEmpty) {
        backgroundImage = entry.bgImagePath!.startsWith('http')
            ? NetworkImage(entry.bgImagePath!)
            : AssetImage(entry.bgImagePath!) as ImageProvider;
      }
    } else if (entry.bgImagePath != null && entry.bgImagePath!.isNotEmpty) {
      backgroundImage = entry.bgImagePath!.startsWith('http')
          ? NetworkImage(entry.bgImagePath!)
          : AssetImage(entry.bgImagePath!) as ImageProvider;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        image: backgroundImage != null
            ? DecorationImage(image: backgroundImage, fit: BoxFit.cover)
            : null,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Container(
                color: theme.colorScheme.surface.withValues(alpha: 0.4)),
            _buildContent(context, entry),
          ],
        ),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────
  // Stickers/images are NOT spread here — they live inside _buildDescriptionSection
  // so they render at the correct description-local coordinates and scroll
  // with the content, mirroring the entry screen architecture exactly.

  Widget _buildContent(BuildContext context, DiaryEntryModel entry) {
    return Stack(
      children: [
        Column(
          children: [
            _buildAppBar(context, entry),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                          child: _buildHeaderSection(context, entry)),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(
                          child: _buildTitleField(context, entry)),
                      SliverToBoxAdapter(
                          child: _buildDescriptionSection(context, entry)),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
                ),
              ),
            ),
            // Matches the height of _buildActionButtons in the entry screen
            // so the scrollable viewport has the exact same height.
            const SafeArea(child: SizedBox(height: 80)),
          ],
        ),
      ],
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context, DiaryEntryModel entry) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.onSurface,
      forceMaterialTransparency: true,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
          context.read<DiaryBloc>().add(LoadDiaryEntries());
        },
        icon: const Icon(CupertinoIcons.back),
      ),
      actions: [
        IconButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DiaryEntryScreen(entry: entry),
              ),
            );
            if (context.mounted) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (context.mounted) {
                  context.read<DiaryBloc>().add(FetchEntryById(entry.id));
                }
              });
            }
          },
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Entry',
        ),
        IconButton(
          onPressed: () => showDeleteEntryDialog(context, entry),
          icon: const Icon(CupertinoIcons.delete),
          tooltip: 'Delete Entry',
        ),
      ],
    );
  }

  // ── Header — pixel-perfect copy of entry screen header ────────────────────

  Widget _buildHeaderSection(BuildContext context, DiaryEntryModel entry) {
    final theme = Theme.of(context);
    final date = entry.date.isNotEmpty
        ? DateTime.tryParse(entry.date) ?? DateTime.now()
        : DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                intl.DateFormat('dd').format(date),
                style: theme.textTheme.headlineLarge!.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  Text(
                    intl.DateFormat('EE').format(date),
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    intl.DateFormat('MMMM yyyy').format(date),
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w900,
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Invisible icon — same size as entry screen dropdown arrow
                  // so this Row renders at the exact same height.
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.transparent,
                  ),
                ],
              ),
              Container(
                height: 10,
                width: 150,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        CircleAvatar(
          backgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.1),
          radius: 25,
          child: Hero(
            tag: 'moodTag${entry.id}',
            child: Text(
              entry.mood.isEmpty ? '😊' : entry.mood,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ],
    );
  }

  // ── Title — identical TextFormField to entry screen ───────────────────────

  Widget _buildTitleField(BuildContext context, DiaryEntryModel entry) {
    final theme = Theme.of(context);
    return IgnorePointer(
      child: TextFormField(
        initialValue: entry.title,
        maxLines: null,
        maxLength: 50,
        decoration: InputDecoration(
          hintText: 'Title',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontFamily: entry.fontFamily,
          ),
          border: InputBorder.none,
          counterStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 24,
          color: theme.colorScheme.onSurface,
          fontFamily: entry.fontFamily,
        ),
      ),
    );
  }

  // ── Description — overlays rendered inside the Stack ──────────────────────
  // Mirrors the entry screen _buildDescriptionSection exactly:
  //   • images rendered first (lower Z)
  //   • stickers rendered last (upper Z, always on top of images)
  // Coordinates are description-local so they align with the editor positions.

  Widget _buildDescriptionSection(
      BuildContext context, DiaryEntryModel entry) {
    final stickers = _parseStickers(entry);
    final images = _parseImages(entry);

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── TextField (bottom) ──────────────────────────────────────────
          IgnorePointer(
            child: TextFormField(
              initialValue: entry.content,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
              style: TextStyle(fontFamily: entry.fontFamily),
            ),
          ),

          // ── Images (middle) ─────────────────────────────────────────────
          ...images.map((i) => ImageOverlay(image: i)),

          // ── Stickers (top) ──────────────────────────────────────────────
          ...stickers.map((s) => StickerOverlay(sticker: s)),
        ],
      ),
    );
  }
}