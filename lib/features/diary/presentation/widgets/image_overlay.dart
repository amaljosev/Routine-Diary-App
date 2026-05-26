import 'dart:io';
import 'package:flutter/material.dart';
import 'package:routine/features/diary/presentation/blocs/diary_entry/diary_entry_bloc.dart';
import 'package:routine/features/diary/presentation/widgets/full_screen_image_viewer.dart';

class ImageOverlay extends StatelessWidget {
  final DiaryImage image;

  const ImageOverlay({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    

    return Positioned(
      left: image.x,
      top: image.y,
      child: Transform.rotate(
        angle: image.rotation,
        child: GestureDetector(
          onTap: () {
          FullScreenImageViewer.show(
            context,
            imagePath: image.imagePath,
            heroTag: 'diary_image_${image.id}',
          );
        },
          child: SizedBox(
            width: 100,
            height: 100,
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
      ),
    );
  }
}