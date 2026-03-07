import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
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

// ============================================================
// ================== TRANSFORMABLE ITEM WIDGET ===============
// ============================================================

typedef ItemTransformUpdate = void Function({
  required String id,
  required double x,
  required double y,
  required double scale,
  required double rotation,
});

class _TransformableItem extends StatefulWidget {
  final String id;
  final Widget child;
  final Offset initialPosition;
  final double initialScale;
  final double initialRotation;
  final bool isSelected;
  final ItemTransformUpdate onUpdate;
  final VoidCallback onRemove;
  final VoidCallback onSelect;
  final double? baseWidth;
  final double? baseHeight;

  const _TransformableItem({
    Key? key,
    required this.id,
    required this.child,
    required this.initialPosition,
    required this.initialScale,
    required this.initialRotation,
    required this.isSelected,
    required this.onUpdate,
    required this.onRemove,
    required this.onSelect,
    this.baseWidth,
    this.baseHeight,
  }) : super(key: key);

  @override
  __TransformableItemState createState() => __TransformableItemState();
}

class __TransformableItemState extends State<_TransformableItem> {
  late Offset _position;
  late double _scale;
  late double _rotation;

  Offset? _lastFocalPoint;
  double _initialScaleOnGesture = 1.0;
  double _initialRotationOnGesture = 0.0;

  Offset? _resizeStartFocal;
  double _resizeStartScale = 1.0;

  static const double _handlePadding = 20.0;
  static const double _stickerBaseSize = 100.0;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _scale = widget.initialScale;
    _rotation = widget.initialRotation;
  }

  void _updateTransform() {
    widget.onUpdate(
      id: widget.id,
      x: _position.dx,
      y: _position.dy,
      scale: _scale,
      rotation: _rotation,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _initialScaleOnGesture = _scale;
    _initialRotationOnGesture = _rotation;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 1) {
      final delta = details.focalPoint - _lastFocalPoint!;
      setState(() {
        _position += delta;
        _lastFocalPoint = details.focalPoint;
      });
    } else {
      final newScale = (_initialScaleOnGesture * details.scale).clamp(0.3, 5.0);
      final newRotation = _initialRotationOnGesture + details.rotation;

      setState(() {
        _scale = newScale;
        _rotation = newRotation;
        final delta = details.focalPoint - _lastFocalPoint!;
        _position += delta;
        _lastFocalPoint = details.focalPoint;
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _updateTransform();
  }

  void _onTap() => widget.onSelect();

  void _onRemoveTap() => widget.onRemove();

  void _onRotateTap() {
    setState(() {
      _rotation += 90 * 3.14159 / 180;
    });
    _updateTransform();
  }

  void _onHandlePanDown(DragDownDetails details, Alignment alignment) {
    _resizeStartFocal = details.localPosition;
    _resizeStartScale = _scale;
  }

  void _onHandlePanUpdate(DragUpdateDetails details, Alignment alignment) {
    if (_resizeStartFocal == null) return;

    double dx = details.delta.dx;
    double dy = details.delta.dy;

    double projection = dx + dy;

    double scaleFactor = 1 + projection / 100;

    setState(() {
      _scale = (_resizeStartScale * scaleFactor).clamp(0.3, 5.0);
    });
  }

  void _onHandlePanEnd(DragEndDetails details) {
    _resizeStartFocal = null;
    _updateTransform();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.baseWidth != null && widget.baseHeight != null) {
      final width = widget.baseWidth! * _scale;
      final height = widget.baseHeight! * _scale;

      content = SizedBox(width: width, height: height, child: widget.child);
    } else {
      content = Container(
        width: _stickerBaseSize * _scale,
        height: _stickerBaseSize * _scale,
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: widget.child,
        ),
      );
    }

    content = Transform.rotate(angle: _rotation, child: content);

    final paddedChild = Padding(
      padding: const EdgeInsets.all(_handlePadding),
      child: content,
    );

    final List<Widget> stackChildren = [paddedChild];

    if (widget.isSelected) {
      stackChildren.addAll([
        _buildHandle(Alignment.topLeft),
        _buildHandle(Alignment.topRight),
        _buildHandle(Alignment.bottomLeft),
        _buildHandle(Alignment.bottomRight),
        Positioned(
          top: 0,
          left: 0,
          child: GestureDetector(
            onTap: _onRemoveTap,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _onRotateTap,
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue,
              child: Icon(Icons.rotate_right, size: 16, color: Colors.white),
            ),
          ),
        ),
      ]);
    }

    return Positioned(
      left: _position.dx - _handlePadding,
      top: _position.dy - _handlePadding,
      child: GestureDetector(
        onTap: _onTap,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: Stack(clipBehavior: Clip.none, children: stackChildren),
      ),
    );
  }

  Widget _buildHandle(Alignment alignment) {
    double? left, right, top, bottom;

    if (alignment.x == -1) left = 0;
    if (alignment.x == 1) right = 0;
    if (alignment.y == -1) top = 0;
    if (alignment.y == 1) bottom = 0;

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: GestureDetector(
        onPanDown: (d) => _onHandlePanDown(d, alignment),
        onPanUpdate: (d) => _onHandlePanUpdate(d, alignment),
        onPanEnd: _onHandlePanEnd,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ================== MAIN SCREEN =============================
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

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  final bool _isDraggingOverlay = false;

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
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
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
          log(state.errorMessage.toString());
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

  // ============================================================
  // ================== UPDATED BACKGROUND METHOD ===============
  // ============================================================
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
      } else {
        if (state.bgImage.isNotEmpty) {
          backgroundImage = state.bgImage.startsWith('http')
              ? NetworkImage(state.bgImage)
              : AssetImage(state.bgImage);
        }
      }
    } else if (state.bgImage.isNotEmpty) {
      backgroundImage = state.bgImage.startsWith('http')
          ? NetworkImage(state.bgImage)
          : AssetImage(state.bgImage);
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
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCustomScrollView(state, context),
            ),
          ),
        ),
        _buildActionButtons(context, state),
      ],
    );
  }

  Widget _buildAppBarSaveButton(BuildContext context, DiaryEntryState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isValid = state.title.isNotEmpty || state.description.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: isValid ? () => _saveEntry(context, state) : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: theme.colorScheme.onPrimary,
          backgroundColor: theme.colorScheme.primary,
          disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
      bgColor: state.bgColor?.toARGB32().toRadixString(16).padLeft(8, '0'),
      stickersJson: jsonEncode(state.stickers.map((s) => s.toJson()).toList()),
      imagesJson: jsonEncode(state.images.map((i) => i.toJson()).toList()),
      bgImagePath: state.bgImage.isNotEmpty ? state.bgImage : null,
      bgLocalPath: state.bgLocalPath,
      bgGalleryImagePath: state.bgGalleryImage,
      fontFamily: state.fontFamily,
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
        SliverToBoxAdapter(child: _buildTitleField(context, state)),
        SliverToBoxAdapter(child: _buildDescriptionSection(state, context)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

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
    return GestureDetector(
      onTap: () => _selectDate(context, state),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            intl.DateFormat('dd').format(state.date),
            style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          Row(
            spacing: 5,
            children: [
              Text(
                intl.DateFormat('EE').format(state.date),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
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
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          Container(
            height: 10,
            width: 150,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector(DiaryEntryState state, BuildContext context) {
    return GestureDetector(
      onTap: () => _selectMood(context),
      child: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        radius: 25,
        child: Text(state.mood, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

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

  Widget _buildDescriptionSection(DiaryEntryState state, BuildContext context) {
    return Container(
      key: _descriptionKey,
      constraints: const BoxConstraints(minHeight: 400),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            ignoring: state.selectedStickerId != null || state.selectedImageId != null,
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

    return _TransformableItem(
      id: sticker.id,
      initialPosition: Offset(sticker.x, sticker.y),
      initialScale: sticker.size,
      initialRotation: sticker.rotation,
      isSelected: isSelected,
      onSelect: () => _bloc.add(SelectSticker(sticker.id)),
      onUpdate: ({
        required id,
        required x,
        required y,
        required scale,
        required rotation,
      }) {
        _bloc.add(UpdateStickerTransform(id, x, y, scale, rotation));
      },
      onRemove: () => _bloc.add(RemoveSticker(sticker.id)),
      child: sticker.localPath != null && File(sticker.localPath!).existsSync()
          ? SvgPicture.file(
              File(sticker.localPath!),
              fit: BoxFit.contain,
            )
          : SvgPicture.network(
              sticker.url,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Container(
                color: Colors.grey.shade300,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
    );
  }

  // ============================================================
  // ======================== IMAGE ==============================
  // ============================================================

  Widget _buildImage(DiaryImage image, DiaryEntryState state) {
    final isSelected = state.selectedImageId == image.id;

    final double safeWidth = image.width.isFinite ? image.width : 120;
    final double safeHeight = image.height.isFinite ? image.height : 120;

    return _TransformableItem(
      id: image.id,
      initialPosition: Offset(image.x, image.y),
      initialScale: image.scale,
      initialRotation: image.rotation,
      isSelected: isSelected,
      baseWidth: safeWidth,
      baseHeight: safeHeight,
      onSelect: () => _bloc.add(SelectImage(image.id)),
      onUpdate: ({
        required id,
        required x,
        required y,
        required scale,
        required rotation,
      }) {
        _bloc.add(UpdateImageTransform(id, x, y, scale, rotation));
      },
      onRemove: () => _bloc.add(RemoveImage(image.id)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(image.imagePath), fit: BoxFit.cover),
      ),
    );
  }

  // ============================================================
  // ================== ACTION BUTTONS ==========================
  // ============================================================

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
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.layers_outlined,
                        label: 'Change Background',
                        onPressed: _onBgImagePressed,
                        context: context,
                      ),
                      _buildActionButton(
                        icon: Icons.text_fields_rounded,
                        label: 'Change Font',
                        onPressed: _onFontPressed,
                        context: context,
                      ),
                      _buildActionButton(
                        icon: Icons.palette_outlined,
                        label: 'Background Color',
                        onPressed: _onBgColorPressed,
                        context: context,
                      ),
                      _buildActionButton(
                        icon: Icons.photo_outlined,
                        label: 'Add Sticker photo',
                        onPressed: _onPhotoPressed,
                        context: context,
                      ),
                      if (state.bgGalleryImage != null ||
                          state.bgImage.isNotEmpty ||
                          state.bgColor != null)
                        _buildActionButton(
                          icon: Icons.close,
                          label: 'Clear Background',
                          onPressed: () => _bloc.add(const ClearBackground()),
                          context: context,
                        ),
                      _buildActionButton(
                        icon: Icons.format_list_bulleted,
                        label: 'Add Bullet',
                        onPressed: _onBulletPressed,
                        context: context,
                      ),
                      _buildActionButton(
                        icon: Icons.emoji_emotions_outlined,
                        label: 'Add Sticker',
                        onPressed: _onStickerPressed,
                        context: context,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
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
          decoration: BoxDecoration(shape: BoxShape.circle),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: theme.colorScheme.primary, size: 25),
          ),
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
      onPresetSelected: (imageUrl) => _bloc.add(SelectSupabaseBackground(imageUrl)),
      onGallerySelected: (filePath) => _bloc.add(CropAndSetBackgroundImage(filePath)),
      onClear: () => _bloc.add(const ClearBackground()),
    );
  }

  void _onFontPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FontPickerSheet(
        currentFont: _bloc.state.fontFamily ?? 'Quicksand',
        onFontSelected: (fontFamily) {
          _bloc.add(FontChanged(fontFamily));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onBulletPressed() {
    final FocusScopeNode focusScope = FocusScope.of(context);
    if (!focusScope.hasFocus) {
      focusScope.requestFocus(FocusNode());
    }

    final text = _descriptionController.text;
    final selection = _descriptionController.selection;

    int insertPos;
    if (selection.isValid &&
        selection.baseOffset >= 0 &&
        selection.baseOffset <= text.length) {
      insertPos = selection.baseOffset;
    } else {
      insertPos = text.length;
    }
    final newText = '${text.substring(0, insertPos)}\n• ${text.substring(insertPos)}';
    final newCursorPos = insertPos + 3;
    _descriptionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _onStickerPressed() {
    DiaryUIHelpers.openStickerPicker(context, (url, localPath) {
      final position = _calculateCenterPosition();
      _bloc.add(StickerAdded(url, localPath, position.dx, position.dy));
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

// ============================================================
// =================== SIZE ADJUSTER WIDGETS ==================
// ============================================================

class _StickerSizeAdjuster extends StatefulWidget {
  final StickerModel sticker;
  final RenderBox descriptionRenderBox;

  const _StickerSizeAdjuster({
    required this.sticker,
    required this.descriptionRenderBox,
  });

  @override
  State<_StickerSizeAdjuster> createState() => __StickerSizeAdjusterState();
}

class __StickerSizeAdjusterState extends State<_StickerSizeAdjuster> {
  late double _currentScale;
  static const double minScale = 0.3;
  static const double maxScale = 3.0;
  static const double scaleStep = 0.1;

  @override
  void initState() {
    super.initState();
    _currentScale = widget.sticker.size;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<DiaryEntryBloc>();
    const double kBaseStickerFontSize = 40.0;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Transform.scale(
                scale: _currentScale,
                child: Text(
                  widget.sticker.url,
                  style: TextStyle(fontSize: kBaseStickerFontSize),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Scale: ${(_currentScale * 100).round()}%',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _currentScale,
              min: minScale,
              max: maxScale,
              divisions: ((maxScale - minScale) / scaleStep).round(),
              label: '${(_currentScale * 100).round()}%',
              onChanged: (value) {
                setState(() => _currentScale = value);
                bloc.add(UpdateStickerSize(widget.sticker.id, value));
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSizeButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final newScale = (_currentScale - scaleStep).clamp(minScale, maxScale);
                    setState(() => _currentScale = newScale);
                    bloc.add(UpdateStickerSize(widget.sticker.id, newScale));
                  },
                ),
                _buildSizeButton(
                  icon: Icons.add,
                  onPressed: () {
                    final newScale = (_currentScale + scaleStep).clamp(minScale, maxScale);
                    setState(() => _currentScale = newScale);
                    bloc.add(UpdateStickerSize(widget.sticker.id, newScale));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.error,
              ),
              title: Text(
                'Remove Sticker',
                style: TextStyle(
                  color: theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                bloc.add(RemoveSticker(widget.sticker.id));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _ImageSizeAdjuster extends StatefulWidget {
  final DiaryImage image;
  final RenderBox descriptionRenderBox;

  const _ImageSizeAdjuster({
    required this.image,
    required this.descriptionRenderBox,
  });

  @override
  State<_ImageSizeAdjuster> createState() => __ImageSizeAdjusterState();
}

class __ImageSizeAdjusterState extends State<_ImageSizeAdjuster> {
  late double _currentScale;
  static const double minScale = 0.5;
  static const double maxScale = 3.0;

  @override
  void initState() {
    super.initState();
    _currentScale = widget.image.scale;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bloc = context.read<DiaryEntryBloc>();

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(widget.image.imagePath),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey,
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Scale: ${(_currentScale * 100).round()}%',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _currentScale,
              min: minScale,
              max: maxScale,
              divisions: 25,
              label: '${(_currentScale * 100).round()}%',
              onChanged: (value) {
                setState(() => _currentScale = value);
                bloc.add(UpdateImageSize(widget.image.id, value));
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSizeButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final newScale = (_currentScale - 0.2).clamp(minScale, maxScale);
                    setState(() => _currentScale = newScale);
                    bloc.add(UpdateImageSize(widget.image.id, newScale));
                  },
                ),
                _buildSizeButton(
                  icon: Icons.add,
                  onPressed: () {
                    final newScale = (_currentScale + 0.2).clamp(minScale, maxScale);
                    setState(() => _currentScale = newScale);
                    bloc.add(UpdateImageSize(widget.image.id, newScale));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: isDark ? Colors.white : theme.colorScheme.error,
              ),
              title: Text(
                'Remove Image',
                style: TextStyle(
                  color: isDark ? Colors.white : theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                bloc.add(RemoveImage(widget.image.id));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

const List<Map<String, String>> availableFonts = [
  {'display': 'Quicksand', 'family': 'Quicksand'},
  {'display': 'Caveat', 'family': 'Caveat'},
  {'display': 'Cormorant Garamond', 'family': 'CormorantGaramond'},
  {'display': 'Dancing Script', 'family': 'DancingScript'},
  {'display': 'Playfair Display', 'family': 'PlayfairDisplay'},
];

class _FontPickerSheet extends StatelessWidget {
  final String currentFont;
  final ValueChanged<String> onFontSelected;

  const _FontPickerSheet({
    required this.currentFont,
    required this.onFontSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose Font',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: availableFonts.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.primary),
                itemBuilder: (context, index) {
                  final font = availableFonts[index];
                  final isSelected = font['family'] == currentFont;
                  return ListTile(
                    leading: isSelected
                        ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                        : const Icon(Icons.circle_outlined),
                    title: Text(
                      font['display']!,
                      style: TextStyle(
                        fontFamily: font['family'],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'The quick brown fox jumps over the lazy dog',
                      style: TextStyle(
                        fontFamily: font['family'],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onFontSelected(font['family']!),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}