import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/diary/presentation/blocs/diary_entry/diary_entry_bloc.dart';

/// Bottom sheet for adjusting a diary image's scale and removing it.
class ImageSizeAdjuster extends StatefulWidget {
  final DiaryImage image;

  const ImageSizeAdjuster({super.key, required this.image});

  @override
  State<ImageSizeAdjuster> createState() => _ImageSizeAdjusterState();
}

class _ImageSizeAdjusterState extends State<ImageSizeAdjuster> {
  late double _currentScale;

  static const double minScale = 0.5;
  static const double maxScale = 3.0;
  static const double _scaleStep = 0.2;

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
            // ── Handle ────────────────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // ── Preview ───────────────────────────────────────────────────
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
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Scale: ${(_currentScale * 100).round()}%',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // ── Slider ────────────────────────────────────────────────────
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

            // ── +/- buttons ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScaleButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final v = (_currentScale - _scaleStep).clamp(minScale, maxScale);
                    setState(() => _currentScale = v);
                    bloc.add(UpdateImageSize(widget.image.id, v));
                  },
                ),
                _ScaleButton(
                  icon: Icons.add,
                  onPressed: () {
                    final v = (_currentScale + _scaleStep).clamp(minScale, maxScale);
                    setState(() => _currentScale = v);
                    bloc.add(UpdateImageSize(widget.image.id, v));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Remove ────────────────────────────────────────────────────
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
}

/// Small circular +/− button used inside [ImageSizeAdjuster].
class _ScaleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ScaleButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: theme.colorScheme.primary,
      ),
    );
  }
}