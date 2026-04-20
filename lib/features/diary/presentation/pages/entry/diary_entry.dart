import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:routine/core/utils/feedback_util.dart';

import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/domain/entities/sticker_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/blocs/diary_entry/diary_entry_bloc.dart';
import 'package:routine/features/diary/presentation/widgets/font_picker_sheet.dart';
import 'package:routine/features/diary/presentation/widgets/transformable_item.dart';
import 'package:routine/features/diary/presentation/widgets/diary_ui_helpers.dart';

// ============================================================
// ================== ENTRY POINT =============================
// ============================================================

class DiaryEntryScreen extends StatelessWidget {
  const DiaryEntryScreen({super.key, required this.entry});

  final DiaryEntryModel? entry;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiaryEntryBloc(),
      child: DiaryEntryForm(entry: entry),
    );
  }
}

// ============================================================
// ================== FORM ====================================
// ============================================================

class DiaryEntryForm extends StatefulWidget {
  const DiaryEntryForm({super.key, required this.entry});

  final DiaryEntryModel? entry;

  @override
  State<DiaryEntryForm> createState() => _DiaryEntryFormState();
}

class _DiaryEntryFormState extends State<DiaryEntryForm> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Key on the description Container — used to:
  ///   1. Measure bounds for clamping overlay movement.
  ///   2. Compute free placement positions.
  final GlobalKey _descriptionKey = GlobalKey();

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  late DiaryEntryBloc _bloc;

  String _previousDescriptionText = '';
  bool _isAutoInsertingBullet = false;
  final bool _isDraggingOverlay = false;

  // ── CHANGE TRACKING: snapshot of the entry when the screen opened ──────────
  // For new entries every field starts empty/default, so any user input
  // immediately counts as a change. For edits we capture the original values
  // from widget.entry so we can diff them later.

  String _originalTitle = '';
  String _originalDescription = '';
  String _originalMood = '😊';
  DateTime? _originalDate;
  String? _originalBgImage;
  String? _originalBgLocalPath;
  String? _originalBgGalleryImage;
  Color? _originalBgColor;
  String? _originalFontFamily;
  int _originalStickerCount = 0;
  int _originalImageCount = 0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _bloc = context.read<DiaryEntryBloc>();

    // Capture original values BEFORE any bloc events mutate state.
    if (widget.entry != null) {
      final e = widget.entry!;
      _originalTitle = e.title;
      _originalDescription = e.content;
      _originalMood = e.mood;
      _originalDate = DateTime.tryParse(e.date);
      _originalBgImage = e.bgImagePath;
      _originalBgLocalPath = e.bgLocalPath;
      _originalBgGalleryImage = e.bgGalleryImagePath;
      _originalFontFamily = e.fontFamily;
      _originalStickerCount =
          (e.stickersJson != null && e.stickersJson!.isNotEmpty)
              ? (jsonDecode(e.stickersJson!) as List).length
              : 0;
      _originalImageCount =
          (e.imagesJson != null && e.imagesJson!.isNotEmpty)
              ? (jsonDecode(e.imagesJson!) as List).length
              : 0;
      // Decode stored bgColor hex → Color for comparison.
      if (e.bgColor != null && e.bgColor!.isNotEmpty) {
        final hex = int.tryParse(e.bgColor!, radix: 16);
        if (hex != null) _originalBgColor = Color(hex);
      }
    }

    _titleController.addListener(
      () => _bloc.add(TitleChanged(_titleController.text)),
    );
    _descriptionController.addListener(_handleDescriptionChange);
    _descriptionController.addListener(
      () => _bloc.add(DescriptionChanged(_descriptionController.text)),
    );

    if (widget.entry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bloc.add(InitializeDiaryEntry(widget.entry));
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.removeListener(_handleDescriptionChange);
    _descriptionController.dispose();
    _scrollController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  // ── Change detection ───────────────────────────────────────────────────────

  /// Returns true if the user has made any edits since the screen opened.
  /// For *new* entries, any non-empty/non-default value counts as a change.
  bool _hasChanges() {
    final s = _bloc.state;

    // For new entries: any content at all counts as a change.
    if (widget.entry == null) {
      return s.title.isNotEmpty ||
          s.description.isNotEmpty ||
          s.stickers.isNotEmpty ||
          s.images.isNotEmpty ||
          s.bgColor != null ||
          s.bgImage.isNotEmpty ||
          s.bgLocalPath != null ||
          s.bgGalleryImage != null ||
          (s.fontFamily != null && s.fontFamily != 'Quicksand');
    }

    // For existing entries: compare against the snapshot taken at initState.
    if (s.title != _originalTitle) return true;
    if (s.description != _originalDescription) return true;
    if (s.mood != _originalMood) return true;
    if (_originalDate != null && s.date != _originalDate) return true;
    if (s.bgImage != (_originalBgImage ?? '')) return true;
    if (s.bgLocalPath != _originalBgLocalPath) return true;
    if (s.bgGalleryImage != _originalBgGalleryImage) return true;
    if (s.bgColor != _originalBgColor) return true;
    if (s.fontFamily != _originalFontFamily) return true;
    if (s.stickers.length != _originalStickerCount) return true;
    if (s.images.length != _originalImageCount) return true;

    return false;
  }

  // ── Back navigation ────────────────────────────────────────────────────────

  /// Called when the user taps the system/hardware back or the leading icon.
  Future<void> _onBackPressed() async {
    if (!_hasChanges()) {
      Navigator.pop(context);
      return;
    }
    await _showUnsavedChangesDialog();
  }

  /// Shows a dialog with three choices: Cancel (stay), Discard, Save.
  Future<void> _showUnsavedChangesDialog() async {
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Unsaved Changes'),
          ],
        ),
        content: Text(
          widget.entry != null
              ? 'You have unsaved changes to this entry. What would you like to do?'
              : 'Your new entry has not been saved yet. What would you like to do?',
          style: theme.textTheme.bodyMedium,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          // ── Cancel: stay on screen ─────────────────────────────────────
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Discard: leave without saving ─────────────────────────
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // close dialog
                  Navigator.pop(context);       // leave screen
                },
                child: Text(
                  'Discard',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              const SizedBox(width: 8),
              // ── Save: persist and leave ────────────────────────────────
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // close dialog
                  _saveEntry(context, _bloc.state);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bounds helper ──────────────────────────────────────────────────────────

  Rect? _getDescriptionBounds() {
    final box =
        _descriptionKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return Rect.fromLTWH(0, 0, box.size.width, box.size.height);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiaryEntryBloc, DiaryEntryState>(
      listenWhen: (p, c) =>
          p.title != c.title ||
          p.description != c.description ||
          p.errorMessage != c.errorMessage,
      listener: (context, state) {
        if (_titleController.text != state.title) {
          _titleController.value = TextEditingValue(
            text: state.title,
            selection: TextSelection.collapsed(offset: state.title.length),
          );
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.value = TextEditingValue(
            text: state.description,
            selection: TextSelection.collapsed(
              offset: state.description.length,
            ),
          );
        }
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          debugPrint(state.errorMessage.toString());
        }
      },
      // ── PopScope intercepts Android back-gesture / back button ────────────
      // canPop: false means Flutter always calls onPopInvokedWithResult first,
      // letting us decide whether to allow the pop or show the dialog.
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return; // already popped — nothing to do
          await _onBackPressed();
        },
        child: BlocBuilder<DiaryEntryBloc, DiaryEntryState>(
          buildWhen: (p, c) {
            if (_isDraggingOverlay) {
              return c.errorMessage != p.errorMessage ||
                  c.title != p.title ||
                  c.description != p.description;
            }
            return true;
          },
          builder: (context, state) =>
              Scaffold(body: _buildBackground(state, context)),
        ),
      ),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────

  Widget _buildBackground(DiaryEntryState state, BuildContext context) {
    final theme = Theme.of(context);
    ImageProvider? backgroundImage;

    if (state.bgGalleryImage != null && state.bgGalleryImage!.isNotEmpty) {
      final file = File(state.bgGalleryImage!);
      if (file.existsSync()) {
        backgroundImage = FileImage(file);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _bloc.add(const ClearBackground());
        });
      }
    } else if (state.bgLocalPath != null && state.bgLocalPath!.isNotEmpty) {
      final file = File(state.bgLocalPath!);
      if (file.existsSync()) {
        backgroundImage = FileImage(file);
      } else if (state.bgImage.isNotEmpty) {
        backgroundImage = state.bgImage.startsWith('http')
            ? NetworkImage(state.bgImage)
            : AssetImage(state.bgImage) as ImageProvider;
      }
    } else if (state.bgImage.isNotEmpty) {
      backgroundImage = state.bgImage.startsWith('http')
          ? NetworkImage(state.bgImage)
          : AssetImage(state.bgImage) as ImageProvider;
    }

    return Container(
      decoration: BoxDecoration(
        color: state.bgColor ?? theme.scaffoldBackgroundColor,
        image: backgroundImage != null
            ? DecorationImage(image: backgroundImage, fit: BoxFit.cover)
            : null,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Container(color: theme.colorScheme.surface.withValues(alpha: 0.4)),
            _buildContent(state, context),
          ],
        ),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(DiaryEntryState state, BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildAppBar(context, state),
            Expanded(
              child: GestureDetector(
                onTap: () => _bloc.add(const DeselectAll()),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildScrollView(state, context),
                ),
              ),
            ),
            _buildActionButtons(context, state),
          ],
        ),
      ],
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  // CHANGE: leading back button now calls _onBackPressed() instead of
  // Navigator.pop() directly, so the unsaved-changes check is triggered.

  AppBar _buildAppBar(BuildContext context, DiaryEntryState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isValid = state.title.isNotEmpty || state.description.isNotEmpty;

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.onSurface,
      forceMaterialTransparency: true,
      // Intercept the leading back button via _onBackPressed.
      leading: IconButton(
        onPressed: _onBackPressed,
        icon: const Icon(CupertinoIcons.back),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ElevatedButton(
            onPressed: isValid ? () => _saveEntry(context, state) : null,
            style: ElevatedButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimary,
              backgroundColor: theme.colorScheme.primary,
              disabledForegroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.3,
              ),
              disabledBackgroundColor: isDark
                  ? theme.colorScheme.surface.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.2),
              elevation: isValid ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(70, 36),
            ),
            child: Text(
              widget.entry != null ? 'UPDATE' : 'SAVE',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Scroll view ────────────────────────────────────────────────────────────

  Widget _buildScrollView(DiaryEntryState state, BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      physics: _isDraggingOverlay
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeaderSection(state, context)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _buildTitleField(context, state)),
        SliverToBoxAdapter(child: _buildDescriptionSection(state, context)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeaderSection(DiaryEntryState state, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _buildDateContent(state, context)),
        _buildMoodSelector(state, context),
      ],
    );
  }

  Widget _buildDateContent(DiaryEntryState state, BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => DiaryUIHelpers.showDatePicker(
        context,
        state.date,
        (val) => _bloc.add(DateChanged(val)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            intl.DateFormat('dd').format(state.date),
            style: theme.textTheme.headlineLarge!.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Row(
            children: [
              Text(
                intl.DateFormat('EE').format(state.date),
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                intl.DateFormat('MMMM yyyy').format(state.date),
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.primary,
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
    );
  }

  Widget _buildMoodSelector(DiaryEntryState state, BuildContext context) {
    return GestureDetector(
      onTap: () => DiaryUIHelpers.openEmojiPicker(
        context,
        (emoji) => _bloc.add(MoodChanged(emoji)),
      ),
      child: CircleAvatar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.1),
        radius: 25,
        child: Text(state.mood, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  // ── Title ──────────────────────────────────────────────────────────────────

  Widget _buildTitleField(BuildContext context, DiaryEntryState state) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _titleController,
      maxLines: null,
      maxLength: 50,
      autofocus: widget.entry == null,
      focusNode: _titleFocusNode,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: 'Title',
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 24,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontFamily: state.fontFamily,
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
        fontFamily: state.fontFamily,
      ),
    );
  }

  // ── Description ────────────────────────────────────────────────────────────

  Widget _buildDescriptionSection(DiaryEntryState state, BuildContext context) {
    return Container(
      key: _descriptionKey,
      constraints: const BoxConstraints(minHeight: 400),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            ignoring:
                state.selectedStickerId != null ||
                state.selectedImageId != null,
            child: TextFormField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
              style: TextStyle(fontFamily: state.fontFamily),
            ),
          ),
          ...state.images.map((i) => _buildImage(i, state)),
          ...state.stickers.map((s) => _buildSticker(s, state)),
        ],
      ),
    );
  }

  // ── Sticker overlay ────────────────────────────────────────────────────────

  Widget _buildSticker(StickerModel sticker, DiaryEntryState state) {
    final isSelected = state.selectedStickerId == sticker.id;

    Widget content;
    if (sticker.localPath != null && File(sticker.localPath!).existsSync()) {
      content = Image.file(File(sticker.localPath!), fit: BoxFit.contain);
    } else if (sticker.url.isNotEmpty && sticker.url.startsWith('http')) {
      content = CachedNetworkImage(
        imageUrl: sticker.url,
        fit: BoxFit.contain,
        placeholder: (_, __) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else if (sticker.url.isNotEmpty) {
      content = Image.asset(sticker.url, fit: BoxFit.contain);
    } else {
      content = const SizedBox();
    }

    return TransformableItem(
      id: sticker.id,
      initialPosition: Offset(sticker.x, sticker.y),
      initialScale: sticker.size,
      initialRotation: sticker.rotation,
      isSelected: isSelected,
      getBounds: _getDescriptionBounds,
      onSelect: () => _bloc.add(SelectSticker(sticker.id)),
      onUpdate:
          ({
            required id,
            required x,
            required y,
            required scale,
            required rotation,
          }) => _bloc.add(UpdateStickerTransform(id, x, y, scale, rotation)),
      onRemove: () => _bloc.add(RemoveSticker(sticker.id)),
      child: content,
    );
  }

  // ── Image overlay ──────────────────────────────────────────────────────────

  Widget _buildImage(DiaryImage image, DiaryEntryState state) {
    final isSelected = state.selectedImageId == image.id;
    final safeWidth = image.width.isFinite ? image.width : 120.0;
    final safeHeight = image.height.isFinite ? image.height : 120.0;

    return TransformableItem(
      id: image.id,
      initialPosition: Offset(image.x, image.y),
      initialScale: image.scale,
      initialRotation: image.rotation,
      isSelected: isSelected,
      baseWidth: safeWidth,
      baseHeight: safeHeight,
      getBounds: _getDescriptionBounds,
      onSelect: () => _bloc.add(SelectImage(image.id)),
      onUpdate:
          ({
            required id,
            required x,
            required y,
            required scale,
            required rotation,
          }) => _bloc.add(UpdateImageTransform(id, x, y, scale, rotation)),
      onRemove: () => _bloc.add(RemoveImage(image.id)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(image.imagePath), fit: BoxFit.cover),
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context, DiaryEntryState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 15),
        child: SizedBox(
          width: double.infinity,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: isDark
                      ? theme.colorScheme.surface
                      : theme.colorScheme.surface.withValues(alpha: 0.9),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      _actionButton(
                        Icons.layers_outlined,
                        'Change Background',
                        _onBgImagePressed,
                        context,
                      ),
                      _actionButton(
                        Icons.text_fields_rounded,
                        'Change Font',
                        _onFontPressed,
                        context,
                      ),
                      _actionButton(
                        Icons.palette_outlined,
                        'Background Color',
                        _onBgColorPressed,
                        context,
                      ),
                      _actionButton(
                        Icons.photo_outlined,
                        'Add Photo',
                        _onPhotoPressed,
                        context,
                      ),
                      if (state.bgGalleryImage != null ||
                          state.bgImage.isNotEmpty ||
                          state.bgColor != null)
                        _actionButton(
                          Icons.close,
                          'Clear Background',
                          () => _bloc.add(const ClearBackground()),
                          context,
                        ),
                      _actionButton(
                        Icons.format_list_bulleted,
                        'Add Bullet',
                        _onBulletPressed,
                        context,
                      ),
                      _actionButton(
                        Icons.auto_awesome_outlined,
                        'Add Sticker',
                        _onStickerPressed,
                        context,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Tooltip(
        message: label,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: theme.colorScheme.primary, size: 25),
          ),
        ),
      ),
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  void _saveEntry(BuildContext context, DiaryEntryState state) {
    final entry = DiaryEntryModel(
      id: widget.entry == null
          ? DateTime.now().toIso8601String()
          : widget.entry!.id,
      title: state.title,
      date: state.date.toIso8601String(),
      preview: state.description,
      mood: state.mood,
      content: state.description,
      createdAt: widget.entry == null
          ? DateTime.now().toIso8601String()
          : widget.entry!.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      bgColor: state.bgColor?.toARGB32().toRadixString(16).padLeft(8, '0'),
      stickersJson: jsonEncode(state.stickers.map((s) => s.toJson()).toList()),
      imagesJson: jsonEncode(state.images.map((i) => i.toJson()).toList()),
      bgImagePath: state.bgImage.isNotEmpty ? state.bgImage : null,
      bgLocalPath: state.bgLocalPath,
      bgGalleryImagePath: state.bgGalleryImage,
      fontFamily: state.fontFamily,
    );
    final isNewEntry = widget.entry == null;

    if (widget.entry != null) {
      context.read<DiaryBloc>().add(UpdateDiaryEntry(entry));
    } else {
      context.read<DiaryBloc>().add(AddDiaryEntry(entry));
    }

    Navigator.pop(context, widget.entry != null ? widget.entry!.id : true);

    if (isNewEntry) {
      FeedbackUtil.askFeedbackIfFirstEntry();
    }
  }

  // ── Toolbar action handlers ────────────────────────────────────────────────

  Future<void> _onPhotoPressed() async {
    if (_bloc.state.images.length >= 10) {
      _showLimitSnackbar('You can only add up to 10 images.');
      return;
    }
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (image != null && mounted) {
        if (_bloc.state.images.length >= 10) {
          _showLimitSnackbar('You can only add up to 10 images.');
          return;
        }
        final position = _findFreePositionForNewItem(100.0, 100.0);
        _bloc.add(ImageAdded(image.path, position.dx, position.dy));
      }
    } catch (e) {
      _bloc.add(SetError('Failed to pick image: $e'));
    }
  }

  void _onStickerPressed() {
    if (_bloc.state.stickers.length >= 20) {
      _showLimitSnackbar('You can only add up to 20 stickers.');
      return;
    }
    DiaryUIHelpers.openStickerPicker(
      context,
      onStickerSelected: (url, x, y) {
        if (_bloc.state.stickers.length >= 20) {
          _showLimitSnackbar('You can only add up to 20 stickers.');
          return;
        }
        final position = _findFreePositionForNewItem(
          TransformableItem.stickerBaseSize,
          TransformableItem.stickerBaseSize,
        );
        _bloc.add(SelectSupabaseSticker(url, position.dx, position.dy));
      },
    );
  }

  void _onBgColorPressed() => DiaryUIHelpers.openColorPicker(
    context,
    (color) => _bloc.add(BgColorChanged(color)),
  );

  void _onBgImagePressed() => DiaryUIHelpers.openBgImagePicker(
    context,
    onPresetSelected: (url) => _bloc.add(SelectSupabaseBackground(url)),
    onGallerySelected: (path) => _bloc.add(CropAndSetBackgroundImage(path)),
    onClear: () => _bloc.add(const ClearBackground()),
  );

  void _onFontPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FontPickerSheet(
        currentFont: _bloc.state.fontFamily ?? 'Quicksand',
        onFontSelected: (family) {
          _bloc.add(FontChanged(family));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onBulletPressed() {
    final text = _descriptionController.text;
    final selection = _descriptionController.selection;
    final insertPos =
        (selection.isValid &&
            selection.baseOffset >= 0 &&
            selection.baseOffset <= text.length)
        ? selection.baseOffset
        : text.length;
    final newText =
        '${text.substring(0, insertPos)}\n• ${text.substring(insertPos)}';
    _descriptionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertPos + 3),
    );
  }

  // ── Auto-bullet ────────────────────────────────────────────────────────────

  void _handleDescriptionChange() {
    if (_isAutoInsertingBullet) return;
    final newText = _descriptionController.text;
    final oldText = _previousDescriptionText;

    if (newText.length == oldText.length + 1 &&
        newText.endsWith('\n') &&
        !oldText.endsWith('\n')) {
      int lineStart = oldText.length - 1;
      while (lineStart > 0 && oldText[lineStart - 1] != '\n') {
        lineStart--;
      }
      final previousLine = oldText.substring(lineStart, oldText.length).trim();

      if (previousLine.startsWith('• ') ||
          previousLine.startsWith('- ') ||
          previousLine.startsWith('* ') ||
          previousLine.startsWith('\u2022 ')) {
        _isAutoInsertingBullet = true;
        final updatedText = '$newText• ';
        _descriptionController.value = TextEditingValue(
          text: updatedText,
          selection: TextSelection.collapsed(offset: updatedText.length),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_descriptionFocusNode.hasFocus) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
        _isAutoInsertingBullet = false;
      }
    }
    _previousDescriptionText = _descriptionController.text;
  }

  // ── Free-position finder ───────────────────────────────────────────────────

  Offset _findFreePositionForNewItem(double width, double height) {
    final renderBox =
        _descriptionKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const Offset(50, 50);

    final size = renderBox.size;
    final state = _bloc.state;

    final existing = <Rect>[
      for (final s in state.stickers)
        Rect.fromLTWH(
          s.x,
          s.y,
          TransformableItem.stickerBaseSize * s.size,
          TransformableItem.stickerBaseSize * s.size,
        ),
      for (final i in state.images)
        Rect.fromLTWH(
          i.x,
          i.y,
          (i.width.isFinite ? i.width : 120.0) * i.scale,
          (i.height.isFinite ? i.height : 120.0) * i.scale,
        ),
    ];

    final startTL = Offset(
      ((size.width - width) / 2).clamp(0.0, size.width - width),
      ((size.height - height) / 2).clamp(0.0, size.height - height),
    );
    if (_isPositionValid(
      Rect.fromLTWH(startTL.dx, startTL.dy, width, height),
      existing,
      size.width,
      size.height,
    )) {
      return startTL;
    }

    final searchCenter = Offset(size.width / 2, size.height / 2);
    for (double r = 20.0; r <= 500.0; r += 20.0) {
      for (int d = 0; d < 8; d++) {
        final angle = d * math.pi / 4;
        final candidateCenter =
            searchCenter + Offset(r * math.cos(angle), r * math.sin(angle));
        final tl = Offset(
          candidateCenter.dx - width / 2,
          candidateCenter.dy - height / 2,
        );
        if (_isPositionValid(
          Rect.fromLTWH(tl.dx, tl.dy, width, height),
          existing,
          size.width,
          size.height,
        )) {
          return tl;
        }
      }
    }
    return startTL;
  }

  bool _isPositionValid(Rect rect, List<Rect> existing, double w, double h) {
    if (rect.left < 0 || rect.top < 0 || rect.right > w || rect.bottom > h) {
      return false;
    }
    return existing.every((r) => !rect.overlaps(r));
  }

  // ── Snackbar ───────────────────────────────────────────────────────────────

  void _showLimitSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}