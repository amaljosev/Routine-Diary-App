import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:consist/core/theme/app_colors.dart';
import 'package:consist/features/diary/data/models/diary_entry_model.dart';
import 'package:consist/features/diary/domain/entities/sticker_model.dart';
import 'package:consist/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:consist/features/diary/presentation/blocs/diary_entry/diary_entry_bloc.dart';
import 'package:consist/features/diary/presentation/widgets/diary_ui_helpers.dart';
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

  @override
  void initState() {
    super.initState();
    _bloc = context.read<DiaryEntryBloc>();
    
    // Initialize with entry data if available
    if (widget.entry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _bloc.add(InitializeDiaryEntry(widget.entry));
          _titleController.text = widget.entry?.title ?? "";
          _descriptionController.text = widget.entry?.content ?? "";
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
    return BlocBuilder<DiaryEntryBloc, DiaryEntryState>(
      builder: (context, state) {
        // Update title controller if state changes
        if (widget.entry != null && mounted) {
          if (_titleController.text != state.title) {
            _titleController.text = state.title;
          }
        }
        
        return Scaffold(body: _buildBackground(state, context));
      },
    );
  }

  Widget _buildBackground(DiaryEntryState state, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: state.bgColor ?? theme.colorScheme.surface,
        image: state.bgImage.isNotEmpty
            ? DecorationImage(
                image: AssetImage(state.bgImage),
                fit: BoxFit.cover,
              )
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
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(CupertinoIcons.back),
          ),
          actions: [
            // Save button in AppBar
            _buildAppBarSaveButton(context, state),
          ],
        ),
        
        Expanded(
          child: GestureDetector(
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

  // AppBar Save Button
  Widget _buildAppBarSaveButton(BuildContext context, DiaryEntryState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isValid = _titleController.text.trim().isNotEmpty ||
                    _descriptionController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: isValid ? () => _saveEntry(context, state) : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: theme.colorScheme.onPrimary,
          backgroundColor: theme.colorScheme.primary,
          disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          disabledBackgroundColor: isDark 
              ? AppColors.darkSurface.withValues(alpha: 0.5)
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

  // Save entry method
  void _saveEntry(BuildContext context, DiaryEntryState state) {
    final entry = DiaryEntryModel(
      id: widget.entry == null
          ? DateTime.now().toIso8601String()
          : widget.entry!.id,
      title: _titleController.text.trim(),
      date: state.date.toIso8601String(),
      preview: _descriptionController.text.trim(),
      mood: state.mood,
      content: _descriptionController.text,
      createdAt: widget.entry == null
          ? DateTime.now().toIso8601String()
          : widget.entry!.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      bgColor: state.bgColor?.toString() ?? Colors.white.toString(),
      stickersJson: jsonEncode(
        state.stickers.map((s) => s.toJson()).toList(),
      ),
      imagesJson: jsonEncode(
        state.images.map((i) => i.toJson()).toList(),
      ),
      bgImagePath: state.bgImage,
    );

    if (widget.entry != null) {
      context.read<DiaryBloc>().add(UpdateDiaryEntry(entry));
    } else {
      context.read<DiaryBloc>().add(AddDiaryEntry(entry));
    }
    
    Navigator.pop(
      context,
      widget.entry != null ? widget.entry!.id : true,
    );
  }

  Widget _buildCustomScrollView(DiaryEntryState state, BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Header section with date and mood
        SliverToBoxAdapter(child: _buildHeaderSection(state, context)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // Title field
        SliverToBoxAdapter(child: _buildTitleField(context)),

        // Description section with stickers and images
        SliverToBoxAdapter(child: _buildDescriptionSection(state, context)),

        // Add some extra space at the bottom
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildHeaderSection(DiaryEntryState state, BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        _buildDateSelector(state, context),
        _buildMoodSelector(state, context),
      ],
    );
  }

  Widget _buildDateSelector(DiaryEntryState state, BuildContext context) {
    return Expanded(
      child: GestureDetector(
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
      onChanged: (value) => _bloc.add(TitleChanged(value)),
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
      constraints: const BoxConstraints(minHeight: 200),
      child: Stack(
        children: [
          // Text field
          TextFormField(
            controller: _descriptionController,
            onChanged: (value) => _bloc.add(DescriptionChanged(value)),
            maxLines: null,
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
            ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // Stickers and images overlay
          ..._buildStickers(state),
          ..._buildImages(state),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, DiaryEntryState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            isDark 
                ? AppColors.darkSurface.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: _buildActionButtons(context),
    );
  }

  List<Widget> _buildStickers(DiaryEntryState state) {
    return state.stickers
        .map((sticker) => _buildSticker(sticker, state))
        .toList();
  }

  Widget _buildSticker(StickerModel sticker, DiaryEntryState state) {
    final isSelected = state.selectedStickerId == sticker.id;
    final theme = Theme.of(context);

    return Positioned(
      left: sticker.x,
      top: sticker.y,
      child: GestureDetector(
        onTap: () {
          _bloc.add(SelectSticker(sticker.id));
        },
        onDoubleTap: () => _showStickerMenu(sticker),
        onLongPress: () => _showStickerMenu(sticker),
        onScaleUpdate: isSelected
            ? (details) {
                final newX = (sticker.x + details.focalPointDelta.dx).toDouble();
                final newY = (sticker.y + details.focalPointDelta.dy).toDouble();
                _bloc.add(UpdateStickerPosition(sticker.id, newX, newY));
                final scaledSize = (sticker.size * details.scale).clamp(12.0, 200.0);
                _bloc.add(UpdateStickerSize(sticker.id, scaledSize.toDouble()));
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : null,
          padding: const EdgeInsets.all(4),
          child: Text(
            sticker.sticker,
            style: TextStyle(fontSize: sticker.size),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildImages(DiaryEntryState state) {
    return state.images.map((image) => _buildImage(image, state)).toList();
  }

  Widget _buildImage(DiaryImage image, DiaryEntryState state) {
    final isSelected = state.selectedImageId == image.id;
    final theme = Theme.of(context);

    return Positioned(
      left: image.x,
      top: image.y,
      child: GestureDetector(
        onTap: () {
          _bloc.add(SelectImage(image.id));
        },
        onDoubleTap: () => _showImageMenu(image),
        onLongPress: () => _showImageMenu(image),
        onScaleUpdate: isSelected
            ? (details) {
                final newX = (image.x + details.focalPointDelta.dx).toDouble();
                final newY = (image.y + details.focalPointDelta.dy).toDouble();
                _bloc.add(UpdateImagePosition(image.id, newX, newY));
                final newScale = (image.scale * details.scale).clamp(0.5, 3.0);
                _bloc.add(UpdateImageSize(image.id, newScale.toDouble()));
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : null,
          padding: const EdgeInsets.all(4),
          child: Transform.scale(
            scale: image.scale,
            child: Image.file(
              File(image.imagePath),
              width: image.width,
              height: image.height,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface.withValues(alpha: 0.9),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
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
        color: AppColors.darkSurface,
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
      color: AppColors.lightSurface,
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

  // Event handlers
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _buildStickerMenu(ctx),
    );

    if (action == 'remove' && context.mounted) {
      _bloc.add(RemoveSticker(sticker.id));
    } else if (action == 'bigger' && context.mounted) {
      _bloc.add(UpdateStickerSize(sticker.id, sticker.size + 4));
    } else if (action == 'smaller' && context.mounted) {
      _bloc.add(
        UpdateStickerSize(sticker.id, (sticker.size - 4).clamp(12, 100)),
      );
    }
  }

  Future<void> _showImageMenu(DiaryImage image) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _buildImageMenu(ctx),
    );

    if (action == 'remove' && context.mounted) {
      _bloc.add(RemoveImage(image.id));
    } else if (action == 'bigger' && context.mounted) {
      _bloc.add(UpdateImageSize(image.id, image.scale + 0.2));
    } else if (action == 'smaller' && context.mounted) {
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
            title: Text('Remove Sticker', style: TextStyle(color: isDark ? Colors.white : null)),
            onTap: () => Navigator.pop(ctx, 'remove'),
          ),
          ListTile(
            leading: Icon(Icons.zoom_in, color: isDark ? Colors.white : null),
            title: Text('Increase Size', style: TextStyle(color: isDark ? Colors.white : null)),
            onTap: () => Navigator.pop(ctx, 'bigger'),
          ),
          ListTile(
            leading: Icon(Icons.zoom_out, color: isDark ? Colors.white : null),
            title: Text('Decrease Size', style: TextStyle(color: isDark ? Colors.white : null)),
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
            title: Text('Remove Image', style: TextStyle(color: isDark ? Colors.white : null)),
            onTap: () => Navigator.pop(ctx, 'remove'),
          ),
          ListTile(
            leading: Icon(Icons.zoom_in, color: isDark ? Colors.white : null),
            title: Text('Increase Size', style: TextStyle(color: isDark ? Colors.white : null)),
            onTap: () => Navigator.pop(ctx, 'bigger'),
          ),
          ListTile(
            leading: Icon(Icons.zoom_out, color: isDark ? Colors.white : null),
            title: Text('Decrease Size', style: TextStyle(color: isDark ? Colors.white : null)),
            onTap: () => Navigator.pop(ctx, 'smaller'),
          ),
        ],
      ),
    );
  }

  void _onPhotoPressed() {
    _pickImageFromGallery();
  }

  void _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && context.mounted) {
        final position = _calculateCenterPosition();
        _bloc.add(ImageAdded(image.path, position.dx, position.dy));
      }
    } catch (e) {
      log('Failed to pick image: $e');
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
      (image) => _bloc.add(BgImageChanged(image)),
    );
  }

  void _onBulletPressed() {
    DiaryUIHelpers.insertBullet(_descriptionController);
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
          _descriptionKey.currentContext?.findRenderObject() as RenderBox;
      final size = renderBox.size;

      final scrollOffset = _scrollController.offset;
      final viewportHeight = MediaQuery.of(context).size.height - 200;

      final centerX = size.width / 2;
      final centerY = (scrollOffset + viewportHeight / 2) - 100;

      return Offset(centerX, centerY);
    } catch (e) {
      return const Offset(150, 150);
    }
  }
}