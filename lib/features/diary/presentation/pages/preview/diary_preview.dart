import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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
    final Color backgroundColor = parsedColor ?? theme.scaffoldBackgroundColor;

    ImageProvider? localImage;
    String? networkUrl;

    if (entry.bgGalleryImagePath != null &&
        entry.bgGalleryImagePath!.isNotEmpty) {
      final file = File(entry.bgGalleryImagePath!);
      if (file.existsSync()) {
        localImage = FileImage(file);
      }
    } else if (entry.bgLocalPath != null && entry.bgLocalPath!.isNotEmpty) {
      final file = File(entry.bgLocalPath!);
      if (file.existsSync()) {
        localImage = FileImage(file);
      } else {
        if (entry.bgImagePath != null && entry.bgImagePath!.isNotEmpty) {
          if (entry.bgImagePath!.startsWith('http')) {
            networkUrl = entry.bgImagePath;
          } else {
            localImage = AssetImage(entry.bgImagePath!);
          }
        }
      }
    } else if (entry.bgImagePath != null && entry.bgImagePath!.isNotEmpty) {
      if (entry.bgImagePath!.startsWith('http')) {
        networkUrl = entry.bgImagePath;
      } else {
        localImage = AssetImage(entry.bgImagePath!);
      }
    }

    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          if (localImage != null)
            Positioned.fill(
              child: Image(
                image: localImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: backgroundColor),
              ),
            )
          else if (networkUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: networkUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: backgroundColor),
                errorWidget: (context, url, error) =>
                    Container(color: backgroundColor),
              ),
            ),

          if (localImage != null || networkUrl != null)
            Positioned.fill(
              child: Container(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),

          SafeArea(child: _buildContent(context, entry)),
        ],
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
          title: null,
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
                SliverToBoxAdapter(child: _buildMoodAndTitle(context, entry)),
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

  // New method for mood and title display
  Widget _buildMoodAndTitle(BuildContext context, DiaryEntryModel entry) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // Mood emoji with background
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              entry.mood.isEmpty ? '😊' : entry.mood,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          // Title
          Expanded(
            child: Text(
              entry.title.isEmpty ? "Untitled Entry" : entry.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Updated date header - removed container decoration
  Widget _buildDateOnlyHeader(BuildContext context, DiaryEntryModel entry) {
    final date = entry.date.isNotEmpty
        ? DateTime.tryParse(entry.date) ?? DateTime.now()
        : DateTime.now();

    return Row(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          intl.DateFormat('dd').format(date),
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          intl.DateFormat('MMM').format(date),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          intl.DateFormat('yyyy').format(date),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ],
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
          // Stickers - positions preserved exactly as saved
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
    if (input == null || input.isEmpty) return null;
    final String s = input.trim();

    if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(s)) {
      return Color(int.parse(s, radix: 16));
    }

    final colorRegex = RegExp(r'^Color\(0x([0-9a-fA-F]{8})\)$');
    final match = colorRegex.firstMatch(s);
    if (match != null) {
      final hex = match.group(1);
      if (hex != null) {
        return Color(int.parse(hex, radix: 16));
      }
    }

    final customRegex = RegExp(
      r'red:\s*([0-9.]+),\s*green:\s*([0-9.]+),\s*blue:\s*([0-9.]+),\s*alpha:\s*([0-9.]+)',
    );
    final customMatch = customRegex.firstMatch(s);
    if (customMatch != null) {
      try {
        final r = double.parse(customMatch.group(1)!);
        final g = double.parse(customMatch.group(2)!);
        final b = double.parse(customMatch.group(3)!);
        final a = double.parse(customMatch.group(4)!);
        return Color.fromRGBO(
          (r * 255).round(),
          (g * 255).round(),
          (b * 255).round(),
          a,
        );
      } catch (_) {}
    }

    String hex = s;
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.startsWith('0x')) hex = hex.substring(2);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length == 8) {
      try {
        return Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }

    return null;
  }
}
