import 'dart:io';
import 'package:flutter/material.dart';
import 'package:routine/features/diary/domain/entities/sticker_model.dart';
import 'package:routine/features/diary/presentation/widgets/transformable_item.dart';

class StickerOverlay extends StatelessWidget {
  final StickerModel sticker;

  const StickerOverlay({super.key, required this.sticker});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: sticker.x,
      top: sticker.y,
      child: Transform.rotate(
        angle: sticker.rotation,
        child: SizedBox(
          width: TransformableItem.stickerBaseSize * sticker.size,
          height: TransformableItem.stickerBaseSize * sticker.size,
          child: FittedBox(
            fit: BoxFit.contain,
            child: _buildImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
  // Always prefer local file
  if (sticker.localPath != null && sticker.localPath!.isNotEmpty) {
    final file = File(sticker.localPath!);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 40));
    }
    // Local file missing — show broken image, never hit network
    return const Icon(Icons.broken_image, size: 40);
  }

  // Only use URL for asset paths (not http URLs)
  if (sticker.url.isNotEmpty && !sticker.url.startsWith('http')) {
    return Image.asset(sticker.url, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 40));
  }

  return const Icon(Icons.broken_image, size: 40);
}
}