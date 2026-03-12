import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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
    if (sticker.localPath != null && sticker.localPath!.isNotEmpty) {
      final file = File(sticker.localPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 40));
      }
      return const Icon(Icons.broken_image, size: 40);
    }

    if (sticker.url.isNotEmpty && sticker.url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: sticker.url,
        fit: BoxFit.contain,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 40),
      );
    }

    if (sticker.url.isNotEmpty) {
      return Image.asset(sticker.url, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 40));
    }

    return const Icon(Icons.broken_image, size: 40);
  }
}