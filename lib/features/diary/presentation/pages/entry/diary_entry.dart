import 'dart:convert';
import 'dart:io';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/domain/entities/sticker_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/blocs/diary_entry/diary_entry_bloc.dart';
import 'package:routine/features/diary/presentation/widgets/diary_ui_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;

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
  final GlobalKey _descriptionKey = GlobalKey();
  late DiaryEntryBloc _bloc;

  /// ---- Gesture tracking ----
  final Map<String, double> _initialScales = {};
  final Map<String, Offset> _lastFocalPoints = {};
  final Map<String, Offset> _initialPositions = {};

  bool _isDraggingOverlay = false;
  StickerModel? _draggingSticker;
  DiaryImage? _draggingImage;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<DiaryEntryBloc>();

    _titleController.addListener(() {
      _bloc.add(TitleChanged(_titleController.text));
    });

    _descriptionController.addListener(() {
      _bloc.add(DescriptionChanged(_descriptionController.text));
    });

    if (widget.entry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _bloc.add(InitializeDiaryEntry(widget.entry));
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiaryEntryBloc, DiaryEntryState>(
      listenWhen: (previous, current) =>
          previous.title != current.title ||
          previous.description != current.description ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (_titleController.text != state.title) {
          _titleController.text = state.title;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _bloc.add(const ClearError());
        }
      },
      child: BlocBuilder<DiaryEntryBloc, DiaryEntryState>(
        buildWhen: (previous, current) {
          if (_isDraggingOverlay) {
            return current.errorMessage != previous.errorMessage ||
                current.title != previous.title ||
                current.description != previous.description;
          }
          return true;
        },
        builder: (context, state) {
          return Scaffold(body: _buildBackground(state, context));
        },
      ),
    );
  }

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
    } else if (state.bgImage.isNotEmpty) {
      backgroundImage = AssetImage(state.bgImage);
    }

    return Container(
      decoration: BoxDecoration(
        // Use theme surface color as fallback
        color: state.bgColor ?? theme.colorScheme.surface,
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

  Widget _buildContent(DiaryEntryState state, BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          forceMaterialTransparency: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(CupertinoIcons.back),
          ),
          actions: [_buildAppBarSaveButton(context, state)],
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _bloc.add(const DeselectAll()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCustomScrollView(state, context),
            ),
          ),
        ),
        _buildBottomSection(context, state),
      ],
    );
  }

  Widget _buildAppBarSaveButton(BuildContext context, DiaryEntryState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isValid = state.title.isNotEmpty && state.description.isNotEmpty;

    return Padding(
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
    );
  }

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
      bgColor: state.bgColor?.toString(),
      stickersJson: jsonEncode(state.stickers.map((s) => s.toJson()).toList()),
      imagesJson: jsonEncode(state.images.map((i) => i.toJson()).toList()),
      bgImagePath: state.bgImage.isNotEmpty ? state.bgImage : null,
      bgGalleryImagePath: state.bgGalleryImage,
    );

    if (widget.entry != null) {
      context.read<DiaryBloc>().add(UpdateDiaryEntry(entry));
    } else {
      context.read<DiaryBloc>().add(AddDiaryEntry(entry));
    }
    Navigator.pop(context, widget.entry != null ? widget.entry!.id : true);
  }

  Widget _buildCustomScrollView(DiaryEntryState state, BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      physics: _isDraggingOverlay
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeaderSection(state, context)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _buildTitleField(context)),
        SliverToBoxAdapter(child: _buildDescriptionSection(state, context)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildHeaderSection(DiaryEntryState state, BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildDateSelector(state, context)),
        const SizedBox(width: 10),
        _buildMoodSelector(state, context),
      ],
    );
  }

  Widget _buildDateSelector(DiaryEntryState state, BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: _buildSoftDecoration(context, 24),
        child: Row(
          children: [
            _buildDateContent(state, context),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateContent(DiaryEntryState state, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          intl.DateFormat('dd').format(state.date),
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          intl.DateFormat('EEEE').format(state.date),
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          intl.DateFormat('MMMM yyyy').format(state.date),
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelector(DiaryEntryState state, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _buildSoftDecoration(context, 16),
      child: GestureDetector(
        onTap: () => _selectMood(context),
        child: Text(state.mood, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _titleController,
      maxLines: null,
      maxLength: 50,
      decoration: InputDecoration(
        hintText: 'Title',
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 24,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
      ),
    );
  }

  Widget _buildDescriptionSection(DiaryEntryState state, BuildContext context) {
    return Container(
      key: _descriptionKey,
      constraints: const BoxConstraints(minHeight: 400),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TextFormField(
            controller: _descriptionController,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: "What's on your mind?",
              border: InputBorder.none,
            ),
          ),
          ...state.stickers.map((s) => _buildSticker(s, state)),
          ...state.images.map((i) => _buildImage(i, state)),
        ],
      ),
    );
  }

  // ============================================================
  // ======================= STICKER =============================
  // ============================================================

  Widget _buildSticker(StickerModel sticker, DiaryEntryState state) {
    final isSelected = state.selectedStickerId == sticker.id;
    final display = _draggingSticker?.id == sticker.id
        ? _draggingSticker!
        : sticker;

    return Positioned(
      left: display.x,
      top: display.y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_isDraggingOverlay) {
            _bloc.add(SelectSticker(sticker.id));
          }
        },
        onDoubleTap: () => _showStickerMenu(sticker),
        onLongPress: () => _showStickerMenu(sticker),

        // Scale gesture handles both pan and zoom
        onScaleStart: (details) {
          _initialScales[sticker.id] = display.size;
          _initialPositions[sticker.id] = Offset(display.x, display.y);
          _lastFocalPoints[sticker.id] = details.focalPoint;
          _draggingSticker = display;
          setState(() => _isDraggingOverlay = true);
        },

        onScaleUpdate: (details) {
          if (_draggingSticker?.id != sticker.id) return;

          // Handle scaling
          final initialScale = _initialScales[sticker.id] ?? display.size;
          final newScale = (initialScale * details.scale).clamp(12.0, 200.0);

          // Handle panning - use focal point delta for smooth movement
          final lastFocal = _lastFocalPoints[sticker.id] ?? details.focalPoint;
          final delta = details.focalPoint - lastFocal;
          _lastFocalPoints[sticker.id] = details.focalPoint;

          // Update position
          final newX = _draggingSticker!.x + delta.dx;
          final newY = _draggingSticker!.y + delta.dy;

          _draggingSticker = _draggingSticker!.copyWith(
            x: newX,
            y: newY,
            size: newScale,
          );

          setState(() {});
        },

        onScaleEnd: (_) {
          if (_draggingSticker != null) {
            _bloc.add(
              UpdateStickerTransform(
                _draggingSticker!.id,
                _draggingSticker!.x,
                _draggingSticker!.y,
                _draggingSticker!.size,
              ),
            );
          }

          _draggingSticker = null;
          _initialScales.remove(sticker.id);
          _initialPositions.remove(sticker.id);
          _lastFocalPoints.remove(sticker.id);
          setState(() => _isDraggingOverlay = false);
        },

        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Text(
              display.sticker,
              style: TextStyle(fontSize: display.size),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ======================== IMAGE ==============================
  // ============================================================

  Widget _buildImage(DiaryImage image, DiaryEntryState state) {
    final isSelected = state.selectedImageId == image.id;
    final display = _draggingImage?.id == image.id ? _draggingImage! : image;

    return Positioned(
      left: display.x,
      top: display.y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_isDraggingOverlay) {
            _bloc.add(SelectImage(image.id));
          }
        },
        onDoubleTap: () => _showImageMenu(image),
        onLongPress: () => _showImageMenu(image),

        // Scale gesture handles both pan and zoom
        onScaleStart: (details) {
          _initialScales[image.id] = display.scale;
          _initialPositions[image.id] = Offset(display.x, display.y);
          _lastFocalPoints[image.id] = details.focalPoint;
          _draggingImage = display;
          setState(() => _isDraggingOverlay = true);
        },

        onScaleUpdate: (details) {
          if (_draggingImage?.id != image.id) return;

          // Handle scaling
          final initialScale = _initialScales[image.id] ?? display.scale;
          final newScale = (initialScale * details.scale).clamp(0.5, 3.0);

          // Handle panning - use focal point delta for smooth movement
          final lastFocal = _lastFocalPoints[image.id] ?? details.focalPoint;
          final delta = details.focalPoint - lastFocal;
          _lastFocalPoints[image.id] = details.focalPoint;

          // Update position
          final newX = _draggingImage!.x + delta.dx;
          final newY = _draggingImage!.y + delta.dy;

          _draggingImage = _draggingImage!.copyWith(
            x: newX,
            y: newY,
            scale: newScale,
          );

          setState(() {});
        },

        onScaleEnd: (_) {
          if (_draggingImage != null) {
            _bloc.add(
              UpdateImageTransform(
                _draggingImage!.id,
                _draggingImage!.x,
                _draggingImage!.y,
                _draggingImage!.scale,
              ),
            );
          }

          _draggingImage = null;
          _initialScales.remove(image.id);
          _initialPositions.remove(image.id);
          _lastFocalPoints.remove(image.id);
          setState(() => _isDraggingOverlay = false);
        },

        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Transform.scale(
              scale: display.scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(display.imagePath),
                  width: display.width,
                  height: display.height,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: display.width,
                      height: display.height,
                      color: Colors.grey,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, DiaryEntryState state) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildActionButtons(context, state),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DiaryEntryState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Use theme surface color
        color: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surface.withValues(alpha: 0.9), // Updated
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 15,bottom: 15,left: 15),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildActionButton(
              icon: Icons.photo,
              label: 'Photo',
              onPressed: _onPhotoPressed,
              context: context,
            ),
            _buildActionButton(
              icon: Icons.palette,
              label: 'BG Color',
              onPressed: _onBgColorPressed,
              context: context,
            ),
            _buildActionButton(
              icon: Icons.image,
              label: 'BG Image',
              onPressed: _onBgImagePressed,
              context: context,
            ),
            if (state.bgGalleryImage != null ||
                state.bgImage.isNotEmpty ||
                state.bgColor != null)
              _buildActionButton(
                icon: Icons.clear,
                label: 'Clear BG',
                onPressed: () => _bloc.add(const ClearBackground()),
                context: context,
              ),
            _buildActionButton(
              icon: Icons.format_list_bulleted,
              label: 'Bullet',
              onPressed: _onBulletPressed,
              context: context,
            ),
            _buildActionButton(
              icon: Icons.emoji_emotions,
              label: 'Sticker',
              onPressed: _onStickerPressed,
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildSoftDecoration(BuildContext context, double radius) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (isDark) {
      return BoxDecoration(
        // Use theme surface color instead of AppColors.darkSurface
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: theme.colorScheme.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
    return BoxDecoration(
      // Use theme surface color instead of AppColors.lightSurface
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: theme.colorScheme.primary.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: theme.colorScheme.onPrimary,
          backgroundColor: theme.colorScheme.primary,
          elevation: isDark ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate(BuildContext context, DiaryEntryState state) {
    DiaryUIHelpers.showDatePicker(
      context,
      state.date,
      (val) => _bloc.add(DateChanged(val)),
    );
  }

  void _selectMood(BuildContext context) {
    DiaryUIHelpers.openEmojiPicker(
      context,
      (emoji) => _bloc.add(MoodChanged(emoji)),
    );
  }

  Future<void> _showStickerMenu(StickerModel sticker) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      // Use theme surface color
      backgroundColor: Theme.of(context).colorScheme.surface, // Updated
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _buildStickerMenu(ctx),
    );
    if (action == 'remove' && mounted) {
      _bloc.add(RemoveSticker(sticker.id));
    } else if (action == 'bigger' && mounted) {
      _bloc.add(UpdateStickerSize(sticker.id, sticker.size + 4));
    } else if (action == 'smaller' && mounted) {
      _bloc.add(
        UpdateStickerSize(sticker.id, (sticker.size - 4).clamp(12, 100)),
      );
    }
  }

  Future<void> _showImageMenu(DiaryImage image) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      // Use theme surface color
      backgroundColor: Theme.of(context).colorScheme.surface, // Updated
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _buildImageMenu(ctx),
    );
    if (action == 'remove' && mounted) {
      _bloc.add(RemoveImage(image.id));
    } else if (action == 'bigger' && mounted) {
      _bloc.add(UpdateImageSize(image.id, image.scale + 0.2));
    } else if (action == 'smaller' && mounted) {
      _bloc.add(UpdateImageSize(image.id, (image.scale - 0.2).clamp(0.5, 3.0)));
    }
  }

  Widget _buildStickerMenu(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.delete, color: isDark ? Colors.white : null),
            title: Text(
              'Remove Sticker',
              style: TextStyle(color: isDark ? Colors.white : null),
            ),
            onTap: () => Navigator.pop(ctx, 'remove'),
          ),
          ListTile(
            leading: Icon(Icons.zoom_in, color: isDark ? Colors.white : null),
            title: Text(
              'Increase Size',
              style: TextStyle(color: isDark ? Colors.white : null),
            ),
            onTap: () => Navigator.pop(ctx, 'bigger'),
          ),
          ListTile(
            leading: Icon(Icons.zoom_out, color: isDark ? Colors.white : null),
            title: Text(
              'Decrease Size',
              style: TextStyle(color: isDark ? Colors.white : null),
            ),
            onTap: () => Navigator.pop(ctx, 'smaller'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMenu(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.delete, color: isDark ? Colors.white : null),
            title: Text(
              'Remove Image',
              style: TextStyle(color: isDark ? Colors.white : null),
            ),
            onTap: () => Navigator.pop(ctx, 'remove'),
          ),
          ListTile(
            leading: Icon(Icons.zoom_in, color: isDark ? Colors.white : null),
            title: Text(
              'Increase Size',
              style: TextStyle(color: isDark ? Colors.white : null),
            ),
            onTap: () => Navigator.pop(ctx, 'bigger'),
          ),
          ListTile(
            leading: Icon(Icons.zoom_out, color: isDark ? Colors.white : null),
            title: Text(
              'Decrease Size',
              style: TextStyle(color: isDark ? Colors.white : null),
            ),
            onTap: () => Navigator.pop(ctx, 'smaller'),
          ),
        ],
      ),
    );
  }

  void _onPhotoPressed() => _pickImageFromGallery();

  void _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        final position = _calculateCenterPosition();
        _bloc.add(ImageAdded(image.path, position.dx, position.dy));
      }
    } catch (e) {
      _bloc.add(SetError('Failed to pick image: $e'));
    }
  }

  void _onBgColorPressed() {
    DiaryUIHelpers.openColorPicker(
      context,
      (color) => _bloc.add(BgColorChanged(color)),
    );
  }

  void _onBgImagePressed() {
    DiaryUIHelpers.openBgImagePicker(
      context,
      onPresetSelected: (assetPath) => _bloc.add(BgImageChanged(assetPath)),
      onGallerySelected: (filePath) =>
          _bloc.add(CropAndSetBackgroundImage(filePath)),
      onClear: () => _bloc.add(const ClearBackground()),
    );
  }

  void _onBulletPressed() {
    final text = _descriptionController.text;
    final selection = _descriptionController.selection;
    final buffer = StringBuffer();
    buffer.write(text.substring(0, selection.start));
    buffer.write('\n• ');
    buffer.write(text.substring(selection.end));
    final newText = buffer.toString();
    final newPosition = selection.start + 3;
    _descriptionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newPosition),
    );
  }

  void _onStickerPressed() {
    DiaryUIHelpers.openStickerPicker(context, (sticker) {
      final position = _calculateCenterPosition();
      _bloc.add(StickerAdded(sticker, position.dx, position.dy));
    });
  }

  Offset _calculateCenterPosition() {
    try {
      final RenderBox renderBox =
          _descriptionKey.currentContext!.findRenderObject() as RenderBox;
      final size = renderBox.size;
      return Offset(size.width / 2, size.height / 2);
    } catch (e) {
      return const Offset(150, 150);
    }
  }
}
