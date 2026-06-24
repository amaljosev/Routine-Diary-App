import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:routine/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:routine/features/premium/presentation/widgets/paywall_sheet.dart';
import 'package:routine/features/settings/domain/custom_theme_builder.dart';
import 'package:routine/features/settings/domain/custom_theme_model.dart';
import 'package:routine/features/settings/presentation/bloc/apptheme_bloc.dart';
import 'package:routine/features/settings/presentation/pages/theme/custom_color_screen.dart';
import 'package:routine/features/settings/presentation/pages/theme/theme_image_helper.dart';

// ── Default fallback asset (theme index 0 header) ────────────────────────────
const String _kDefaultHeader = 'assets/img/themes/theme_2.webp';

// ── Built-in asset header options ─────────────────────────────────────────────
const List<String> _kAssetHeaders = [
  'assets/img/themes/theme_1.webp',
  'assets/img/themes/theme_2.webp',
  'assets/img/themes/theme_3.webp',
  'assets/img/themes/theme_4.webp',
  'assets/img/themes/theme_5.webp',
  'assets/img/themes/theme_6.webp',
  'assets/img/themes/theme_7.webp',
];

class CustomThemeScreen extends StatefulWidget {
  const CustomThemeScreen({super.key});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  // ── Draft state ──────────────────────────────────────────────────────────
  late CustomThemeModel _draft;
  late CustomThemeModel
  _original; // snapshot when screen opened – for dirty check
  bool _initialized = false;

  // ── Palette list (built-in + custom sentinel) ────────────────────────────
  late final List<PaletteInfo> _palettes;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _palettes = buildPaletteInfoList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final saved = context.read<ThemeBloc>().state.customThemeModel;
      final initial = saved ?? CustomThemeModel.defaultModel();
      _draft = initial;
      _original = initial;
    }
  }

  // ── Dirty check ──────────────────────────────────────────────────────────

  bool get _isDirty =>
      _draft.headerImagePath != _original.headerImagePath ||
      _draft.paletteType != _original.paletteType ||
      _draft.builtInPaletteIndex != _original.builtInPaletteIndex ||
      _draft.customColors != _original.customColors;

  // ── Image helpers ─────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Header Image',
          // ignore: use_build_context_synchronously
          toolbarColor: Theme.of(context).colorScheme.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Header Image',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null) return;

    // Copy into app-local storage so path stays valid.
    final appDir = await getApplicationDocumentsDirectory();
    final customImgDir = Directory(p.join(appDir.path, 'custom_theme_headers'));
    await customImgDir.create(recursive: true);
    final fileName = 'header_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = p.join(customImgDir.path, fileName);
    await File(cropped.path).copy(destPath);

    setState(() {
      _draft = _draft.copyWith(headerImagePath: destPath);
    });
  }

  Future<void> _pickFromAssets() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AssetPickerSheet(assets: _kAssetHeaders),
    );
    if (chosen == null) return;
    setState(() {
      _draft = _draft.copyWith(headerImagePath: chosen);
    });
  }

  void _removeHeader() {
    setState(() {
      _draft = _draft.copyWith(headerImagePath: _kDefaultHeader);
    });
  }

  void _showEditImageOptions() {
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.image_outlined, color: primary),
              title: const Text('Choose from App Assets'),
              onTap: () {
                Navigator.pop(context);
                _pickFromAssets();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _resetToDefault() {
    setState(() {
      _draft = CustomThemeModel.defaultModel();
    });
  }

  // ── Apply ─────────────────────────────────────────────────────────────────

  void _apply() {
  final isPremium = context.read<PremiumBloc>().state.isPremium;
 
  if (isPremium) {
    _applyTheme();
  } else {
    // FIX Bug 4: Use 'onSuccess' — matches the parameter name in paywall_sheet.dart
    showPaywallSheet(
      context,
      onSuccess: _applyTheme,
    );
  }
}
 
void _applyTheme() {
  context.read<ThemeBloc>().add(ApplyCustomTheme(_draft));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Custom theme applied!'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
  Navigator.of(context).pop();
}

  // ── Back / discard ────────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. If you go back now they will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Custom Color round-trip ───────────────────────────────────────────────

  Future<void> _openCustomColor() async {
    final initialColors = _draft.customColors ?? CustomColorSet.defaultColors();

    final result = await Navigator.of(context).push<CustomColorSet>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ThemeBloc>(),
          child: CustomColorScreen(initialColors: initialColors),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _draft = _draft.copyWith(
          paletteType: PaletteType.custom,
          customColors: result,
        );
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onBg = theme.colorScheme.onSurface;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Customize Theme'),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _resetToDefault,
              child: Text(
                'Reset',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // ── Header preview ─────────────────────────────────────────────
            _HeaderPreview(imagePath: _draft.headerImagePath),

            // ── Header action buttons ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                      onPressed: _showEditImageOptions,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      label: Text(
                        'Remove',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      onPressed: _removeHeader,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Palette section header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'Choose a Palette',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onBg,
                ),
              ),
            ),

            // ── Palette list ───────────────────────────────────────────────
            ..._palettes.asMap().entries.map((entry) {
              final idx = entry.key;
              final palette = entry.value;
              final isSelected =
                  _draft.paletteType == PaletteType.builtIn &&
                  _draft.builtInPaletteIndex == idx;

              return _PaletteTile(
                palette: palette,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _draft = _draft.copyWith(
                      paletteType: PaletteType.builtIn,
                      builtInPaletteIndex: idx,
                      clearCustomColors: true,
                    );
                  });
                },
              );
            }),

            // ── Custom Color option ────────────────────────────────────────
            _CustomColorTile(
              isSelected: _draft.paletteType == PaletteType.custom,
              customColors: _draft.customColors,
              onTap: _openCustomColor,
            ),
          ],
        ),

        // ── Apply button ───────────────────────────────────────────────────
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Apply This Theme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderPreview extends StatelessWidget {
  final String imagePath;

  const _HeaderPreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return ThemeImageHelper.buildHeader(
      imagePath,
      height: 200,
      errorBuilder: (_, __, ___) => Container(
        height: 200,
        color: primary.withValues(alpha: 0.2),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: primary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Palette tile ──────────────────────────────────────────────────────────────

class _PaletteTile extends StatelessWidget {
  final PaletteInfo palette;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaletteTile({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? palette.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Color swatches
              _ColorSwatch(
                primary: palette.primary,
                secondary: palette.secondary,
                background: palette.background,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      palette.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? palette.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      palette.isDark ? 'Dark theme' : 'Light theme',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: palette.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color background;

  const _ColorSwatch({
    required this.primary,
    required this.secondary,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 36,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 6,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: secondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Color tile ─────────────────────────────────────────────────────────

class _CustomColorTile extends StatelessWidget {
  final bool isSelected;
  final CustomColorSet? customColors;
  final VoidCallback onTap;

  const _CustomColorTile({
    required this.isSelected,
    required this.customColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.10)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accent
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Rainbow swatch
              Container(
                width: 52,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.red,
                      Colors.orange,
                      Colors.yellow,
                      Colors.green,
                      Colors.blue,
                      Colors.purple,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Color',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? accent
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customColors != null
                          ? 'Custom colors configured'
                          : 'Tap to pick your own colors',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: isSelected
                    ? accent
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Asset header picker bottom sheet ─────────────────────────────────────────

class _AssetPickerSheet extends StatelessWidget {
  final List<String> assets;

  const _AssetPickerSheet({required this.assets});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Choose Header Image',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: assets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => Navigator.of(ctx).pop(assets[i]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  assets[i],
                  width: 240,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
