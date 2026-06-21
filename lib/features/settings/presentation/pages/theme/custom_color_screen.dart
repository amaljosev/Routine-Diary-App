import 'package:flutter/material.dart';
import 'package:routine/features/diary/presentation/widgets/bottom_nav_bar.dart';
import 'package:routine/features/settings/domain/custom_theme_model.dart';

class CustomColorScreen extends StatefulWidget {
  final CustomColorSet initialColors;

  const CustomColorScreen({super.key, required this.initialColors});

  @override
  State<CustomColorScreen> createState() => _CustomColorScreenState();
}

class _CustomColorScreenState extends State<CustomColorScreen> {
  late CustomColorSet _draft;
  late CustomColorSet _original;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialColors;
    _original = widget.initialColors;
  }

  bool get _isDirty => _draft != _original;

  void _reset() {
    setState(() {
      _draft = CustomColorSet.defaultColors();
    });
  }

  void _done() {
    Navigator.of(context).pop(_draft);
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard color changes?'),
        content: const Text(
          'Going back without saving will lose your color edits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Color picker bottom sheet ───────────────────────────────────────────

  Future<void> _pickColor({
    required String label,
    required Color current,
    required ValueChanged<Color> onChanged,
  }) async {
    final picked = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ColorPickerSheet(label: label, initial: current),
    );
    if (picked != null) {
      setState(() => onChanged(picked));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final colorRows = <_ColorRow>[
      _ColorRow(
        label: 'Primary',
        subtitle: 'App bar, buttons, FAB',
        icon: Icons.format_paint_rounded,
        color: _draft.primary,
        onTap: () => _pickColor(
          label: 'Primary Color',
          current: _draft.primary,
          onChanged: (c) => _draft = _draft.copyWith(primary: c),
        ),
      ),
      _ColorRow(
        label: 'Secondary',
        subtitle: 'Accents, badges, chips',
        icon: Icons.auto_awesome_rounded,
        color: _draft.secondary,
        onTap: () => _pickColor(
          label: 'Secondary Color',
          current: _draft.secondary,
          onChanged: (c) => _draft = _draft.copyWith(secondary: c),
        ),
      ),
      _ColorRow(
        label: 'Surface',
        subtitle: 'Cards, bottom sheets, dialogs',
        icon: Icons.crop_square_rounded,
        color: _draft.surface,
        onTap: () => _pickColor(
          label: 'Surface Color',
          current: _draft.surface,
          onChanged: (c) => _draft = _draft.copyWith(surface: c),
        ),
      ),
      _ColorRow(
        label: 'Background',
        subtitle: 'Scaffold / screen background',
        icon: Icons.layers_rounded,
        color: _draft.background,
        onTap: () => _pickColor(
          label: 'Background Color',
          current: _draft.background,
          onChanged: (c) => _draft = _draft.copyWith(background: c),
        ),
      ),
      _ColorRow(
        label: 'Text',
        subtitle: 'Primary text color on background',
        icon: Icons.text_fields_rounded,
        color: _draft.onBackground,
        onTap: () => _pickColor(
          label: 'Text / On-Surface Color',
          current: _draft.onBackground,
          onChanged: (c) => _draft = _draft.copyWith(onBackground: c),
        ),
      ),
      _ColorRow(
        label: 'Error',
        subtitle: 'Error states, destructive actions',
        icon: Icons.error_outline_rounded,
        color: _draft.error,
        onTap: () => _pickColor(
          label: 'Error Color',
          current: _draft.error,
          onChanged: (c) => _draft = _draft.copyWith(error: c),
        ),
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop(null);
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              title: const Text(
                'Custom Colors',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              actions: [
                TextButton.icon(
                  onPressed: _reset,
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Reset',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Live preview ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _LivePreview(draft: _draft),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'PALETTE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),

            // ── Color rows ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: colorRows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _ColorRowTile(row: colorRows[i]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                // Dark mode toggle
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      _draft.isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                    ),
                    label: Text(_draft.isDark ? 'Dark' : 'Light'),
                    onPressed: () {
                      setState(() {
                        _draft = _draft.copyWith(isDark: !_draft.isDark);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(0, 52),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Done
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _done,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Use These Colors',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data + sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ColorRow {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Future<void> Function() onTap;

  const _ColorRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ColorRowTile extends StatelessWidget {
  final _ColorRow row;

  const _ColorRowTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = _isColorLight(row.color);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: row.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Color chip
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: row.color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: row.color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  row.icon,
                  size: 20,
                  color: isLight ? Colors.black54 : Colors.white70,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _hexLabel(row.color),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isColorLight(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.light;

  static String _hexLabel(Color c) {
    final hex = c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${hex.substring(2)}'; // strip alpha
  }
}

// ── Live preview banner ───────────────────────────────────────────────────────
//
// Mirrors the real DiaryScreen layout (header + entry card) and embeds the
// *actual* CustomBottomNav widget — not a fake mockup — so the accent color
// shown here is exactly what the glass bottom nav will look like in the app.

class _LivePreview extends StatelessWidget {
  final CustomColorSet draft;

  const _LivePreview({required this.draft});

  @override
  Widget build(BuildContext context) {
    final chipTextColor =
        ThemeData.estimateBrightnessForColor(draft.surface) == Brightness.light
        ? Colors.black87
        : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: draft.background,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Mock diary header — mirrors DiaryScreen's "Recent Entries"
          // SliverAppBar row, tinted with the chosen primary color ───────
          Container(
            width: double.infinity,
            color: draft.primary,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                const Text(
                  'Recent Entries',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: draft.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: draft.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '${DateTime.now().day}/${DateTime.now().month}',
                    style: TextStyle(
                      color: chipTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Mock entry card ──────────────────────────────────────────
          Container(
            width: double.infinity,
            color: draft.background,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: draft.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: draft.secondary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: draft.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 9,
                          decoration: BoxDecoration(
                            color: draft.onBackground.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 9,
                          width: 100,
                          decoration: BoxDecoration(
                            color: draft.onBackground.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: draft.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: draft.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── The real CustomBottomNav, themed with the draft colors ────
          // Wrapping it in Theme(...) means the glass nav's accent color
          // updates live as the user edits the primary swatch — this is
          // the actual widget that ships in DiaryScreen, not a stand-in.
          Container(
            width: double.infinity,
            color: draft.background,
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: draft.primary,
                  brightness: draft.isDark ? Brightness.dark : Brightness.light,
                ),
              ),
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: IgnorePointer(
                  child: CustomBottomNav(
                    onCalendarTap: () {},
                    onSettingsTap: () {},
                    onFabTap: () {},
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10, right: 14, top: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Live Preview',
                style: TextStyle(
                  fontSize: 10,
                  color: draft.onBackground.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Color Picker Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ColorPickerSheet extends StatefulWidget {
  final String label;
  final Color initial;

  const _ColorPickerSheet({required this.label, required this.initial});

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSVColor _hsv;
  late TextEditingController _hexController;

  // Preset palette for quick selection
  static const List<Color> _presets = [
    Color(0xFF1976D2),
    Color(0xFF7B1FA2),
    Color(0xFF2E7D32),
    Color(0xFFF57C00),
    Color(0xFFD32F2F),
    Color(0xFF00897B),
    Color(0xFF0288D1),
    Color(0xFF5D4037),
    Color(0xFF455A64),
    Color(0xFF37474F),
    Color(0xFFFFFFFF),
    Color(0xFFF5F5F5),
    Color(0xFF212121),
    Color(0xFF121212),
    Color(0xFFE3F2FD),
    Color(0xFFFFF3E0),
    Color(0xFFE8F5E9),
    Color(0xFFF3E5F5),
    Color(0xFF1E1A2B),
    Color(0xFF0F1419),
    Color(0xFF1E2A1E),
    Color(0xFF90CAF9),
    Color(0xFFB39DDB),
    Color(0xFFA5D6A7),
  ];

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _hexController = TextEditingController(text: _hexOf(_hsv.toColor()));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _hexOf(Color c) =>
      c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

  void _applyHex(String value) {
    final cleaned = value.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final intVal = int.tryParse('FF$cleaned', radix: 16);
      if (intVal != null) {
        setState(() => _hsv = HSVColor.fromColor(Color(intVal)));
      }
    }
  }

  void _setHsv(HSVColor value) {
    setState(() {
      _hsv = value;
      _hexController.value = TextEditingValue(
        text: _hexOf(_hsv.toColor()),
        selection: TextSelection.collapsed(
          offset: _hexController.selection.baseOffset.clamp(0, 6),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _hsv.toColor();
    final isLight =
        ThemeData.estimateBrightnessForColor(selected) == Brightness.light;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title + close
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Preview swatch + hex input
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: selected.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      decoration: InputDecoration(
                        prefixText: '#  ',
                        labelText: 'Hex code',
                        counterText: '',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _applyHex,
                      onChanged: (v) {
                        if (v.length == 6) _applyHex(v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // ── HSV sliders ──────────────────────────────────────────
              _SliderRow(
                label: 'Hue',
                value: _hsv.hue / 360,
                trackGradient: LinearGradient(
                  colors: List.generate(
                    7,
                    (i) => HSVColor.fromAHSV(1, i * 60, 1, 1).toColor(),
                  ),
                ),
                onChanged: (v) => _setHsv(_hsv.withHue(v * 360)),
              ),
              const SizedBox(height: 10),
              _SliderRow(
                label: 'Saturation',
                value: _hsv.saturation,
                trackGradient: LinearGradient(
                  colors: [
                    HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
                    HSVColor.fromAHSV(1, _hsv.hue, 1, _hsv.value).toColor(),
                  ],
                ),
                onChanged: (v) => _setHsv(_hsv.withSaturation(v)),
              ),
              const SizedBox(height: 10),
              _SliderRow(
                label: 'Brightness',
                value: _hsv.value,
                trackGradient: LinearGradient(
                  colors: [
                    Colors.black,
                    HSVColor.fromAHSV(
                      1,
                      _hsv.hue,
                      _hsv.saturation,
                      1,
                    ).toColor(),
                  ],
                ),
                onChanged: (v) => _setHsv(_hsv.withValue(v)),
              ),
              const SizedBox(height: 22),
              // ── Preset swatches ──────────────────────────────────────
              Text(
                'PRESETS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _presets.map((c) {
                  final isSel = selected.toARGB32() == c.toARGB32();
                  return GestureDetector(
                    onTap: () => _setHsv(HSVColor.fromColor(c)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel
                              ? theme.colorScheme.primary
                              : Colors.black.withValues(alpha: 0.08),
                          width: isSel ? 2.5 : 1,
                        ),
                      ),
                      child: isSel
                          ? Icon(
                              Icons.check_rounded,
                              size: 16,
                              color:
                                  ThemeData.estimateBrightnessForColor(c) ==
                                      Brightness.light
                                  ? Colors.black87
                                  : Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // ── Actions ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(selected),
                      style: FilledButton.styleFrom(
                        backgroundColor: selected,
                        foregroundColor: isLight
                            ? Colors.black87
                            : Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Select Color',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final LinearGradient trackGradient;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.trackGradient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9,
                elevation: 2,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              trackShape: _GradientTrackShape(gradient: trackGradient),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: onChanged,
              activeColor: Colors.transparent,
              inactiveColor: Colors.transparent,
              thumbColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientTrackShape extends SliderTrackShape {
  final LinearGradient gradient;

  const _GradientTrackShape({required this.gradient});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    context.canvas.drawRRect(rRect, paint);
  }
}
