import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/diary/domain/entities/sticker_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary_entry/diary_entry_bloc.dart';

/// Bottom sheet for adjusting a sticker's scale and removing it.
class StickerSizeAdjuster extends StatefulWidget {
  final StickerModel sticker;

  const StickerSizeAdjuster({super.key, required this.sticker});

  @override
  State<StickerSizeAdjuster> createState() => _StickerSizeAdjusterState();
}

class _StickerSizeAdjusterState extends State<StickerSizeAdjuster> {
  late double _currentScale;

  static const double minScale = 0.3;
  static const double maxScale = 3.0;
  static const double scaleStep = 0.1;
  static const double _previewSize = 80.0;

  @override
  void initState() {
    super.initState();
    _currentScale = widget.sticker.size;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Transform.scale(
                scale: _currentScale,
                child: _buildPreview(),
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
              divisions: ((maxScale - minScale) / scaleStep).round(),
              label: '${(_currentScale * 100).round()}%',
              onChanged: (value) {
                setState(() => _currentScale = value);
                bloc.add(UpdateStickerSize(widget.sticker.id, value));
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
                    final v = (_currentScale - scaleStep).clamp(minScale, maxScale);
                    setState(() => _currentScale = v);
                    bloc.add(UpdateStickerSize(widget.sticker.id, v));
                  },
                ),
                _ScaleButton(
                  icon: Icons.add,
                  onPressed: () {
                    final v = (_currentScale + scaleStep).clamp(minScale, maxScale);
                    setState(() => _currentScale = v);
                    bloc.add(UpdateStickerSize(widget.sticker.id, v));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Remove ────────────────────────────────────────────────────
            ListTile(
              leading: Icon(
                Icons.delete,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : theme.colorScheme.error,
              ),
              title: Text(
                'Remove Sticker',
                style: TextStyle(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : theme.colorScheme.error,
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

  Widget _buildPreview() {
    if (widget.sticker.localPath != null &&
        File(widget.sticker.localPath!).existsSync()) {
      return Image.file(
        File(widget.sticker.localPath!),
        width: _previewSize,
        height: _previewSize,
        fit: BoxFit.contain,
      );
    }
    if (widget.sticker.url.isNotEmpty &&
        widget.sticker.url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: widget.sticker.url,
        width: _previewSize,
        height: _previewSize,
        fit: BoxFit.contain,
        placeholder: (_, __) =>
            SizedBox(width: _previewSize, height: _previewSize),
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    if (widget.sticker.url.isNotEmpty) {
      return Image.asset(
        widget.sticker.url,
        width: _previewSize,
        height: _previewSize,
        fit: BoxFit.contain,
      );
    }
    return SizedBox(width: _previewSize, height: _previewSize);
  }
}

/// Small circular +/− button used inside [StickerSizeAdjuster].
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