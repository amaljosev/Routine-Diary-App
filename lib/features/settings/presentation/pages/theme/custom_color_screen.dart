import 'package:flutter/material.dart';
import 'package:routine/features/settings/domain/custom_theme_model.dart';

/// Opened from [CustomThemeScreen] when the user taps "Custom Color".
/// Returns a [CustomColorSet] via [Navigator.pop] when the user taps Done,
/// or null if they press back without changes.
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
        title: const Text('Discard color changes?'),
        content: const Text(
          'Going back without saving will lose your color edits.',
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

  // ── Color picker row ──────────────────────────────────────────────────────

  Future<void> _pickColor({
    required String label,
    required Color current,
    required ValueChanged<Color> onChanged,
  }) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => _ColorPickerDialog(label: label, initial: current),
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
        label: 'Primary Color',
        subtitle: 'Main brand color – app bar, buttons, FAB',
        color: _draft.primary,
        onTap: () => _pickColor(
          label: 'Primary Color',
          current: _draft.primary,
          onChanged: (c) => _draft = _draft.copyWith(primary: c),
        ),
      ),
      _ColorRow(
        label: 'Secondary Color',
        subtitle: 'Accent – badges, chips, highlights',
        color: _draft.secondary,
        onTap: () => _pickColor(
          label: 'Secondary Color',
          current: _draft.secondary,
          onChanged: (c) => _draft = _draft.copyWith(secondary: c),
        ),
      ),
      _ColorRow(
        label: 'Surface Color',
        subtitle: 'Cards, bottom sheets, dialogs',
        color: _draft.surface,
        onTap: () => _pickColor(
          label: 'Surface Color',
          current: _draft.surface,
          onChanged: (c) => _draft = _draft.copyWith(surface: c),
        ),
      ),
      _ColorRow(
        label: 'Background Color',
        subtitle: 'Scaffold / screen background',
        color: _draft.background,
        onTap: () => _pickColor(
          label: 'Background Color',
          current: _draft.background,
          onChanged: (c) => _draft = _draft.copyWith(background: c),
        ),
      ),
      _ColorRow(
        label: 'Text / On-Surface Color',
        subtitle: 'Primary text color on background',
        color: _draft.onBackground,
        onTap: () => _pickColor(
          label: 'Text / On-Surface Color',
          current: _draft.onBackground,
          onChanged: (c) => _draft = _draft.copyWith(onBackground: c),
        ),
      ),
      _ColorRow(
        label: 'Error Color',
        subtitle: 'Error states, destructive actions',
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
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Custom Colors'),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _reset,
              child: Text('Reset',
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Mini live preview ──────────────────────────────────────────
            _LivePreview(draft: _draft),
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Tap any color to change it',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
            // ── Color rows ─────────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: colorRows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final row = colorRows[i];
                  return _ColorRowTile(row: row);
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Dark mode toggle
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(_draft.isDark
                        ? Icons.dark_mode
                        : Icons.light_mode_outlined),
                    label:
                        Text(_draft.isDark ? 'Dark Mode' : 'Light Mode'),
                    onPressed: () {
                      setState(() {
                        _draft = _draft.copyWith(isDark: !_draft.isDark);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Done
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _done,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
  final Color color;
  final Future<void> Function() onTap;

  const _ColorRow({
    required this.label,
    required this.subtitle,
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
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final isLight = _isColorLight(row.color);

    return GestureDetector(
      onTap: row.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Color chip
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: row.color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? Colors.white24
                        : Colors.black.withValues(alpha: 0.12),
                  ),
                ),
                child: Center(
                  child: Text(
                    _hexLabel(row.color),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: isLight ? Colors.black54 : Colors.white70,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.label,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.colorize_outlined,
                size: 20,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.35),
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

class _LivePreview extends StatelessWidget {
  final CustomColorSet draft;

  const _LivePreview({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: draft.background,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fake app bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: draft.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'My Diary',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Fake card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: draft.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: draft.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: draft.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 10,
                        color: draft.onBackground.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 10,
                        width: 100,
                        color: draft.onBackground.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Live Preview',
              style: TextStyle(
                fontSize: 10,
                color: draft.onBackground.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple HSV Color Picker Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ColorPickerDialog extends StatefulWidget {
  final String label;
  final Color initial;

  const _ColorPickerDialog({required this.label, required this.initial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv;

  // Preset palette for quick selection
  static const List<Color> _presets = [
    Color(0xFF1976D2), Color(0xFF7B1FA2), Color(0xFF2E7D32),
    Color(0xFFF57C00), Color(0xFFD32F2F), Color(0xFF00897B),
    Color(0xFF0288D1), Color(0xFF5D4037), Color(0xFF455A64),
    Color(0xFF37474F), Color(0xFFFFFFFF), Color(0xFFF5F5F5),
    Color(0xFF212121), Color(0xFF121212), Color(0xFFE3F2FD),
    Color(0xFFFFF3E0), Color(0xFFE8F5E9), Color(0xFFF3E5F5),
    Color(0xFF1E1A2B), Color(0xFF0F1419), Color(0xFF1E2A1E),
    Color(0xFF90CAF9), Color(0xFFB39DDB), Color(0xFFA5D6A7),
  ];

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _hsv.toColor();
    final isLight =
        ThemeData.estimateBrightnessForColor(selected) == Brightness.light;

    return AlertDialog(
      title: Text(widget.label),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Preview chip ────────────────────────────────────────────
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: selected,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${selected.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isLight ? Colors.black87 : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Hue slider ──────────────────────────────────────────────
            _SliderRow(
              label: 'H',
              value: _hsv.hue / 360,
              trackGradient: LinearGradient(
                colors: List.generate(
                  7,
                  (i) => HSVColor.fromAHSV(1, i * 60, 1, 1).toColor(),
                ),
              ),
              onChanged: (v) =>
                  setState(() => _hsv = _hsv.withHue(v * 360)),
            ),
            // ── Saturation slider ────────────────────────────────────────
            _SliderRow(
              label: 'S',
              value: _hsv.saturation,
              trackGradient: LinearGradient(colors: [
                HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
                HSVColor.fromAHSV(1, _hsv.hue, 1, _hsv.value).toColor(),
              ]),
              onChanged: (v) =>
                  setState(() => _hsv = _hsv.withSaturation(v)),
            ),
            // ── Brightness slider ────────────────────────────────────────
            _SliderRow(
              label: 'B',
              value: _hsv.value,
              trackGradient: LinearGradient(colors: [
                Colors.black,
                HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 1)
                    .toColor(),
              ]),
              onChanged: (v) =>
                  setState(() => _hsv = _hsv.withValue(v)),
            ),
            const SizedBox(height: 12),
            // ── Preset swatches ──────────────────────────────────────────
            SizedBox(
              height: 80,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: _presets.length,
                itemBuilder: (_, i) {
                  final c = _presets[i];
                  final isSel = _hsv.toColor().value == c.value;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _hsv = HSVColor.fromColor(c)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.withValues(alpha: 0.3),
                          width: isSel ? 2.5 : 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_hsv.toColor()),
          child: const Text('Select'),
        ),
      ],
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
          width: 16,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 10,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
              trackShape: _GradientTrackShape(gradient: trackGradient),
            ),
            child: Slider(
              value: value,
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
    final trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
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

    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    context.canvas.drawRRect(rRect, paint);
  }
}