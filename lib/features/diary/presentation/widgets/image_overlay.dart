import 'dart:io';
import 'package:flutter/material.dart';
import 'package:routine/features/diary/presentation/blocs/diary_entry/diary_entry_bloc.dart';

class ImageOverlay extends StatelessWidget {
  final DiaryImage image;

  const ImageOverlay({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    final double safeWidth = image.width.isFinite ? image.width : 120;
    final double safeHeight = image.height.isFinite ? image.height : 120;

    return Positioned(
      left: image.x,
      top: image.y,
      child: Transform.rotate(
        angle: image.rotation,
        child: SizedBox(
          width: safeWidth * image.scale,
          height: safeHeight * image.scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(image.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey,
                child: const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}