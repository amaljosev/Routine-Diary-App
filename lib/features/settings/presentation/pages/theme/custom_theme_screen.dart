// lib/features/settings/presentation/pages/theme/custom_theme_screen.dart

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

// ── Default fallback asset ────────────────────────────────────────────────────
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

class _CustomThemeScreenState extends State<CustomThemeScreen>
    with SingleTickerProviderStateMixin {
  // ── Draft state ──────────────────────────────────────────────────────────
  late CustomThemeModel _draft;
  late CustomThemeModel _original;
  bool _initialized = false;

  // ── Live background preview ───────────────────────────────────────────────
  Color? _previewBg;
  Color? _previewPrimary;

  // ── Palette list ─────────────────────────────────────────────────────────
  late final List<PaletteInfo> _palettes;

  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  // For sliver header collapse detection
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _palettes = buildPaletteInfoList();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    const collapseThreshold = 140.0;
    final collapsed = _scrollController.offset > collapseThreshold;
    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
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
      _syncPreviewColors();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ── Sync live preview colors from current draft ───────────────────────────
  void _syncPreviewColors() {
    if (_draft.paletteType == PaletteType.builtIn) {
      final idx = _draft.builtInPaletteIndex;
      if (idx < _palettes.length) {
        _previewBg = _palettes[idx].background;
        _previewPrimary = _palettes[idx].primary;
      }
    } else if (_draft.paletteType == PaletteType.custom &&
        _draft.customColors != null) {
      _previewBg = _draft.customColors!.background;
      _previewPrimary = _draft.customColors!.primary;
    } else {
      _previewBg = null;
      _previewPrimary = null;
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

    final appDir = await getApplicationDocumentsDirectory();
    final customImgDir =
        Directory(p.join(appDir.path, 'custom_theme_headers'));
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
    final primary = _previewPrimary ?? Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Change Header Image',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_library_outlined, color: primary, size: 20),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Use your own photo',
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome_outlined, color: primary, size: 20),
              ),
              title: const Text('App Themes',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Choose from curated headers',
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _pickFromAssets();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void _resetToDefault() {
    setState(() {
      _draft = CustomThemeModel.defaultModel();
      _syncPreviewColors();
    });
  }

  // ── Apply ─────────────────────────────────────────────────────────────────
  void _apply() {
    final isPremium = context.read<PremiumBloc>().state.isPremium;
    if (isPremium) {
      _applyTheme();
    } else {
      showPaywallSheet(context, onSuccess: _applyTheme);
    }
  }

  void _applyTheme() {
    context.read<ThemeBloc>().add(ApplyCustomTheme(_draft));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Custom theme applied!'),
        backgroundColor: _previewPrimary ?? Theme.of(context).colorScheme.primary,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard changes?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'You have unsaved changes. Going back will lose them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Discard',
                style:
                    TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Custom Color round-trip ───────────────────────────────────────────────
  Future<void> _openCustomColor() async {
    final initialColors =
        _draft.customColors ?? CustomColorSet.defaultColors();
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
        _syncPreviewColors();
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallbackBg = theme.scaffoldBackgroundColor;
    final fallbackPrimary = theme.colorScheme.primary;

    // Live background: animates between selected palette's bg and fallback
    final liveBackground = _previewBg ?? fallbackBg;
    final livePrimary = _previewPrimary ?? fallbackPrimary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        color: liveBackground,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero SliverAppBar ──────────────────────────────────────
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                collapsedHeight: 60,
                stretch: true,
                backgroundColor: liveBackground,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final expandRatio =
                        ((constraints.maxHeight - 60) / (220 - 60))
                            .clamp(0.0, 1.0);
                    final isCollapsed = expandRatio < 0.15;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Header image
                        Opacity(
                          opacity: expandRatio,
                          child: ThemeImageHelper.buildHeader(
                            _draft.headerImagePath,
                            height: 220,
                            errorBuilder: (_, __, ___) => Container(
                              color: livePrimary.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: livePrimary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        // Gradient overlay on the image
                        Opacity(
                          opacity: expandRatio,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.1),
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Collapsed app bar ──────────────────────────
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            bottom: false,
                            child: SizedBox(
                              height: 60,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 20,
                                        color: isCollapsed
                                            ? livePrimary
                                            : Colors.white,
                                      ),
                                      onPressed: () async {
                                        final shouldPop = await _onWillPop();
                                        if (shouldPop && context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                    ),
                                    Expanded(
                                      child: AnimatedOpacity(
                                        opacity: isCollapsed ? 1.0 : 0.0,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Text(
                                          'Customize Theme',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: livePrimary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _resetToDefault,
                                      child: Text(
                                        'Reset',
                                        style: TextStyle(
                                          color: isCollapsed
                                              ? theme.colorScheme.error
                                              : Colors.white.withValues(
                                                  alpha: 0.85),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Expanded hero content ──────────────────────
                        Positioned(
                          bottom: 0,
                          left: 20,
                          right: 20,
                          child: Opacity(
                            opacity: expandRatio,
                            child: SafeArea(
                              top: false,
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 16, top: 60),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Customize',
                                            style: theme
                                                .textTheme.headlineSmall
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                              height: 1,
                                            ),
                                          ),
                                          Text(
                                            'Theme',
                                            style: theme
                                                .textTheme.headlineSmall
                                                ?.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.6),
                                              fontWeight: FontWeight.w300,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Image edit chip
                                    _ImageEditChip(
                                      onTap: _showEditImageOptions,
                                      onRemove: _removeHeader,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Section label: Header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: _SectionLabel(
                    label: 'HEADER IMAGE',
                    primaryColor: livePrimary,
                  ),
                ),
              ),

              // ── Header image action row ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionChip(
                          icon: Icons.edit_outlined,
                          label: 'Change Image',
                          primary: livePrimary,
                          filled: false,
                          onTap: _showEditImageOptions,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionChip(
                          icon: Icons.delete_outline,
                          label: 'Remove',
                          primary: theme.colorScheme.error,
                          filled: false,
                          onTap: _removeHeader,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section label: Palette ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      _SectionLabel(
                        label: 'COLOR PALETTE',
                        primaryColor: livePrimary,
                      ),
                      const Spacer(),
                      // Live "preview" dot
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: livePrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: livePrimary.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live preview',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: livePrimary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Palette tiles ──────────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, idx) {
                    final palette = _palettes[idx];
                    final isSelected =
                        _draft.paletteType == PaletteType.builtIn &&
                            _draft.builtInPaletteIndex == idx;

                    return _PaletteTile(
                      palette: palette,
                      isSelected: isSelected,
                      liveBackground: liveBackground,
                      onTap: () {
                        setState(() {
                          _draft = _draft.copyWith(
                            paletteType: PaletteType.builtIn,
                            builtInPaletteIndex: idx,
                            clearCustomColors: true,
                          );
                          _syncPreviewColors();
                        });
                      },
                    );
                  },
                  childCount: _palettes.length,
                ),
              ),

              // ── Custom Color tile ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _CustomColorTile(
                  isSelected: _draft.paletteType == PaletteType.custom,
                  customColors: _draft.customColors,
                  liveBackground: liveBackground,
                  onTap: _openCustomColor,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // ── Apply button ───────────────────────────────────────────────
          bottomNavigationBar: _ApplyBar(
            primaryColor: livePrimary,
            liveBackground: liveBackground,
            onApply: _apply,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image edit chip (overlaid on the hero image)
// ─────────────────────────────────────────────────────────────────────────────

class _ImageEditChip extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImageEditChip({required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'Edit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color primaryColor;

  const _SectionLabel({required this.label, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: primaryColor,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action chip button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primary;
  final bool filled;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.primary,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: filled ? primary : primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary.withValues(alpha: filled ? 0 : 0.25),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette tile — modern card style
// ─────────────────────────────────────────────────────────────────────────────

class _PaletteTile extends StatelessWidget {
  final PaletteInfo palette;
  final bool isSelected;
  final Color liveBackground;
  final VoidCallback onTap;

  const _PaletteTile({
    required this.palette,
    required this.isSelected,
    required this.liveBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Card surface: slightly offset from the animated background
    final cardColor = isSelected
        ? palette.primary.withValues(alpha: 0.10)
        : theme.colorScheme.surface.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? palette.primary
                : theme.colorScheme.outline.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // ── Stacked swatch ──────────────────────────────────────
              _PaletteSwatch(
                primary: palette.primary,
                secondary: palette.secondary,
                background: palette.background,
              ),
              const SizedBox(width: 14),
              // ── Label ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      palette.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? palette.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (palette.isDark
                                    ? Colors.white
                                    : Colors.black)
                                .withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            palette.isDark ? '🌙 Dark' : '☀️ Light',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Selected checkmark ───────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? Container(
                        key: const ValueKey('check'),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: palette.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16),
                      )
                    : Container(
                        key: const ValueKey('empty'),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _PaletteSwatch extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color background;

  const _PaletteSwatch({
    required this.primary,
    required this.secondary,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 40,
      child: Stack(
        children: [
          // Background rectangle
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08), width: 1),
              ),
            ),
          ),
          // Primary circle
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Secondary accent dot
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: secondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: secondary.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Color tile
// ─────────────────────────────────────────────────────────────────────────────

class _CustomColorTile extends StatelessWidget {
  final bool isSelected;
  final CustomColorSet? customColors;
  final Color liveBackground;
  final VoidCallback onTap;

  const _CustomColorTile({
    required this.isSelected,
    required this.customColors,
    required this.liveBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.08)
              : theme.colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? accent
                : theme.colorScheme.outline.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Rainbow swatch
              Container(
                width: 56,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF6B6B),
                      Color(0xFFFFD93D),
                      Color(0xFF6BCB77),
                      Color(0xFF4D96FF),
                      Color(0xFFC77DFF),
                    ],
                  ),
                ),
                child: customColors != null
                    ? null
                    : const Center(
                        child: Icon(Icons.add_rounded,
                            color: Colors.white, size: 20),
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
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? accent
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      customColors != null
                          ? 'Custom colors configured'
                          : 'Tap to pick your own colors',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? Container(
                        key: const ValueKey('check'),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16),
                      )
                    : Container(
                        key: const ValueKey('arrow'),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Apply button bar (bottom nav)
// ─────────────────────────────────────────────────────────────────────────────

class _ApplyBar extends StatelessWidget {
  final Color primaryColor;
  final Color liveBackground;
  final VoidCallback onApply;

  const _ApplyBar({
    required this.primaryColor,
    required this.liveBackground,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: liveBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onApply,
                borderRadius: BorderRadius.circular(18),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Apply This Theme',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
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
// Asset header picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AssetPickerSheet extends StatelessWidget {
  final List<String> assets;

  const _AssetPickerSheet({required this.assets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                'Choose Header Image',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${assets.length} options',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: assets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => Navigator.of(ctx).pop(assets[i]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Image.asset(
                      assets[i],
                      width: 240,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Theme ${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
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