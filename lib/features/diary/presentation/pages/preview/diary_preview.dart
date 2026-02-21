import 'dart:convert';
import 'dart:io';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/domain/entities/sticker_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/blocs/diary_entry/diary_entry_bloc.dart';
import 'package:routine/features/diary/presentation/pages/entry/diary_entry.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

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

class DiaryEntryPreviewForm extends StatefulWidget {
  final String entryId;

  const DiaryEntryPreviewForm({super.key, required this.entryId});

  @override
  State<DiaryEntryPreviewForm> createState() => _DiaryEntryPreviewFormState();
}

class _DiaryEntryPreviewFormState extends State<DiaryEntryPreviewForm> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _descriptionKey = GlobalKey();
  double scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollOffset);
  }

  void _updateScrollOffset() {
    setState(() {
      scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollOffset);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) =>
          context.read<DiaryBloc>().add(LoadDiaryEntries()),
      child: Scaffold(
        body: BlocBuilder<DiaryBloc, DiaryState>(
          buildWhen: (previous, current) {
            return current.entries.any((e) => e.id == widget.entryId) ||
                previous.isLoading != current.isLoading ||
                previous.errorMessage != current.errorMessage;
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.errorMessage != null) {
              return Center(
                child: Text(
                  "Error: ${state.errorMessage}",
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }

            try {
              final entry = state.entries.firstWhere(
                (e) => e.id == widget.entryId,
              );
              return _buildBackground(context, entry);
            } catch (e) {
              return Center(
                child: Text(
                  "Diary entry not found",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildBackground(BuildContext context, DiaryEntryModel entry) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color? parsedColor = _parseColorFromString(entry.bgColor);
    ImageProvider? backgroundImage;

    if (entry.bgGalleryImagePath != null &&
        entry.bgGalleryImagePath!.isNotEmpty) {
      final file = File(entry.bgGalleryImagePath!);
      if (file.existsSync()) {
        backgroundImage = FileImage(file);
      }
    } else if (entry.bgImagePath != null && entry.bgImagePath!.isNotEmpty) {
      backgroundImage = AssetImage(entry.bgImagePath!);
    }

    // Use scaffold background color as fallback (this matches the theme's background)
    final Color fallbackColor = parsedColor ?? theme.scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        color: backgroundImage == null ? fallbackColor : null,
        image: backgroundImage != null
            ? DecorationImage(image: backgroundImage, fit: BoxFit.cover)
            : null,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.4),
            ),
            _buildContent(context, entry),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DiaryEntryModel entry) {
    final theme = Theme.of(context);

    return Column(
      children: [
        AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DiaryBloc>().add(LoadDiaryEntries());
            },
            icon: Icon(CupertinoIcons.back),
          ),
          title: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry.mood.isEmpty ? '😊' : entry.mood,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              Expanded(
                child: Text(
                  (entry.title.isEmpty) ? "Untitled Entry" : entry.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          forceMaterialTransparency: true,
          automaticallyImplyLeading: true,
          elevation: 0,
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
              icon: Icon(Icons.edit),
              tooltip: 'Edit Entry',
            ),
            IconButton(
              onPressed: () => _showDeleteConfirmation(context, entry),
              icon: Icon(CupertinoIcons.delete),
              tooltip: 'Delete Entry',
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildDateOnlyHeader(context, entry)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: _buildDescriptionSection(context, entry),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDateOnlyHeader(BuildContext context, DiaryEntryModel entry) {
    final date = entry.date.isNotEmpty
        ? DateTime.tryParse(entry.date) ?? DateTime.now()
        : DateTime.now();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        // Use surface color from the current theme (matches dialog/card backgrounds)
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          Text(
            intl.DateFormat('EEEE').format(date),
            style: theme.textTheme.headlineLarge!.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            intl.DateFormat('MMMM yyyy').format(date),
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    DiaryEntryModel entry,
  ) async {
    final theme = Theme.of(context);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Use surface color from theme for the dialog background
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Entry',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this diary entry? This action cannot be undone.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<DiaryBloc>().add(DeleteDiaryEntry(entry.id));
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDescriptionSection(BuildContext context, DiaryEntryModel entry) {
    final theme = Theme.of(context);

    List<StickerModel> stickers = [];
    List<DiaryImage> images = [];

    try {
      stickers = (entry.stickersJson != null)
          ? (List<Map<String, dynamic>>.from(
              jsonDecode(entry.stickersJson ?? '[]'),
            )).map((m) => StickerModel.fromJson(m)).toList()
          : [];
    } catch (_) {}

    try {
      images = (entry.imagesJson != null)
          ? (List<Map<String, dynamic>>.from(
              jsonDecode(entry.imagesJson ?? '[]'),
            )).map((m) => DiaryImage.fromJson(m)).toList()
          : [];
    } catch (_) {}

    return Container(
      key: _descriptionKey,
      constraints: const BoxConstraints(minHeight: 400),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SelectableText(
              entry.content.isEmpty ? "What's on your mind?" : entry.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
          ...stickers.map((sticker) {
            return Positioned(
              left: sticker.x,
              top: sticker.y,
              child: RepaintBoundary(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      sticker.sticker,
                      style: TextStyle(
                        fontSize: sticker.size,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          ...images.map((image) {
            return Positioned(
              left: image.x,
              top: image.y,
              child: RepaintBoundary(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Transform.scale(
                      scale: image.scale,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageWidget(image, theme),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImageWidget(DiaryImage image, ThemeData theme) {
    try {
      if (image.imagePath.isEmpty) return const SizedBox();
      final file = File(image.imagePath);
      if (!file.existsSync()) {
        return Container(
          width: image.width,
          height: image.height,
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.error),
          ),
          child: Icon(
            Icons.broken_image,
            color: theme.colorScheme.error,
            size: 30,
          ),
        );
      }

      return Image.file(
        file,
        width: image.width,
        height: image.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: image.width,
            height: image.height,
            color: Colors.grey,
            child: const Icon(Icons.broken_image, color: Colors.white),
          );
        },
      );
    } catch (_) {
      return const SizedBox();
    }
  }

  Color? _parseColorFromString(String? input) {
    if (input == null) return null;
    final s = input.trim();

    if (s.startsWith('Color(') && s.contains('red:')) {
      try {
        final redMatch = RegExp(r'red:\s*([0-9.]+)').firstMatch(s);
        final greenMatch = RegExp(r'green:\s*([0-9.]+)').firstMatch(s);
        final blueMatch = RegExp(r'blue:\s*([0-9.]+)').firstMatch(s);
        final alphaMatch = RegExp(r'alpha:\s*([0-9.]+)').firstMatch(s);
        final r = double.parse(redMatch?.group(1) ?? '1.0');
        final g = double.parse(greenMatch?.group(1) ?? '1.0');
        final b = double.parse(blueMatch?.group(1) ?? '1.0');
        final a = double.parse(alphaMatch?.group(1) ?? '1.0');
        return Color.fromRGBO(
          (r * 255).round(),
          (g * 255).round(),
          (b * 255).round(),
          a,
        );
      } catch (_) {
        return null;
      }
    }

    try {
      var hex = s;
      if (hex.startsWith('#')) hex = hex.substring(1);
      if (hex.startsWith('0x')) hex = hex.substring(2);
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }
}
