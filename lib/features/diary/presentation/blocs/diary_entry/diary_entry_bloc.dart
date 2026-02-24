import 'dart:convert';
import 'dart:io';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/domain/entities/sticker_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

part 'diary_entry_event.dart';
part 'diary_entry_state.dart';

class DiaryEntryBloc extends Bloc<DiaryEntryEvent, DiaryEntryState> {
  DiaryEntryBloc() : super(DiaryEntryState(date: DateTime.now())) {
    on<InitializeDiaryEntry>(_onInitializeDiaryEntry);
    on<TitleChanged>((event, emit) => emit(state.copyWith(title: event.title)));
    on<DescriptionChanged>(
      (event, emit) => emit(state.copyWith(description: event.description)),
    );
    on<MoodChanged>((event, emit) => emit(state.copyWith(mood: event.mood)));
    on<DateChanged>((event, emit) => emit(state.copyWith(date: event.date)));
    on<BgColorChanged>(_onBgColorChanged);
    on<BgImageChanged>(_onBgImageChanged);
    on<BgGalleryImageChanged>(_onBgGalleryImageChanged);
    on<CropAndSetBackgroundImage>(_onCropAndSetBackgroundImage);
    on<StickerAdded>(_onStickerAdded);
    on<UpdateStickerPosition>(_onUpdateStickerPosition);
    on<UpdateStickerSize>(_onUpdateStickerSize);
    on<UpdateStickerTransform>(_onUpdateStickerTransform);
    on<RemoveSticker>(_onRemoveSticker);
    on<ImageAdded>(_onImageAdded);
    on<UpdateImagePosition>(_onUpdateImagePosition);
    on<UpdateImageSize>(_onUpdateImageSize);
    on<UpdateImageTransform>(_onUpdateImageTransform);
    on<RemoveImage>(_onRemoveImage);
    on<SelectSticker>((event, emit) {
      emit(state.copyWith(
        selectedStickerId: event.id,
        selectedImageId: null,
      ));
    });
    on<SelectImage>((event, emit) {
      emit(state.copyWith(
        selectedImageId: event.id,
        selectedStickerId: null,
      ));
    });
    on<DeselectAll>((event, emit) {
      emit(state.copyWith(
        selectedStickerId: null,
        selectedImageId: null,
      ));
    });
    on<ClearBackground>(_onClearBackground);
    on<SetError>((event, emit) {
      emit(state.copyWith(errorMessage: event.message));
    });
    on<ClearError>((event, emit) {
      emit(state.copyWith(errorMessage: null));
    });
  }

  void _onInitializeDiaryEntry(
  InitializeDiaryEntry event,
  Emitter<DiaryEntryState> emit,
) {
  final e = event.entry;

  if (e != null) {
    // Determine which background to use - prioritize gallery image if exists and file is accessible
    String bgImage = '';
    String? bgGalleryImage = e.bgGalleryImagePath;
    
    // Check if gallery image exists and is accessible
    if (bgGalleryImage != null && bgGalleryImage.isNotEmpty) {
      final file = File(bgGalleryImage);
      if (!file.existsSync()) {
        // If file doesn't exist, fall back to asset image
        bgGalleryImage = null;
        bgImage = e.bgImagePath ?? '';
      }
    } else {
      // No gallery image, use asset image
      bgImage = e.bgImagePath ?? '';
    }

    emit(
      state.copyWith(
        title: e.title,
        description: e.content,
        mood: e.mood,
        // FIX: Use the improved color parser instead of AppConverters
        bgColor: _parseColorFromString(e.bgColor),
        bgImage: bgImage,
        bgGalleryImage: bgGalleryImage,
        stickers: e.stickersJson != null
            ? (jsonDecode(e.stickersJson!) as List)
                  .map((s) => StickerModel.fromJson(s))
                  .toList()
            : [],
        images: e.imagesJson != null
            ? (jsonDecode(e.imagesJson!) as List)
                  .map((i) => DiaryImage.fromJson(i))
                  .toList()
            : [],
        date: DateTime.tryParse(e.date) ?? DateTime.now(),
      ),
    );
  }
}

Color? _parseColorFromString(String? input) {
  if (input == null || input.isEmpty) return null;
  final String s = input.trim();

  final colorRegex = RegExp(r'^Color\(0x([0-9a-fA-F]{8})\)$');
  final match = colorRegex.firstMatch(s);
  if (match != null) {
    final hex = match.group(1);
    if (hex != null) {
      return Color(int.parse(hex, radix: 16));
    }
  }

  // 2. Handle hex string format (8 chars, no prefix)
  if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(s)) {
    return Color(int.parse(s, radix: 16));
  }

  // 3. Handle custom "Color(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)" format
  final customRegex = RegExp(
    r'red:\s*([0-9.]+),\s*green:\s*([0-9.]+),\s*blue:\s*([0-9.]+),\s*alpha:\s*([0-9.]+)',
  );
  final customMatch = customRegex.firstMatch(s);
  if (customMatch != null) {
    try {
      final r = double.parse(customMatch.group(1)!);
      final g = double.parse(customMatch.group(2)!);
      final b = double.parse(customMatch.group(3)!);
      final a = double.parse(customMatch.group(4)!);
      return Color.fromRGBO(
        (r * 255).round(),
        (g * 255).round(),
        (b * 255).round(),
        a,
      );
    } catch (_) {}
  }

  // 4. Handle other hex formats (#, 0x, etc.)
  String hex = s;
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.startsWith('0x')) hex = hex.substring(2);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length == 8) {
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {}
  }

  return null;
}

  void _onBgColorChanged(BgColorChanged event, Emitter<DiaryEntryState> emit) {
    emit(
      state.copyWith(
        bgColor: event.color,
        bgImage: '',
        bgGalleryImage: null,
      ),
    );
  }

  void _onBgImageChanged(BgImageChanged event, Emitter<DiaryEntryState> emit) {
    emit(
      state.copyWith(
        bgImage: event.image,
        bgColor: null,
        bgGalleryImage: null,
      ),
    );
  }

  void _onBgGalleryImageChanged(
    BgGalleryImageChanged event,
    Emitter<DiaryEntryState> emit,
  ) {
    emit(
      state.copyWith(
        bgGalleryImage: event.imagePath,
        bgImage: '',
        bgColor: null,
      ),
    );
  }

  Future<void> _onCropAndSetBackgroundImage(
    CropAndSetBackgroundImage event,
    Emitter<DiaryEntryState> emit,
  ) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: event.imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
        maxWidth: 1080,
        maxHeight: 1920,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Background',
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Crop Background',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        emit(state.copyWith(
          bgGalleryImage: croppedFile.path,
          bgImage: '',
          bgColor: null,
        ));
      } else {
        emit(state.copyWith(
          bgGalleryImage: event.imagePath,
          bgImage: '',
          bgColor: null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to crop image: $e',
        bgGalleryImage: event.imagePath,
        bgImage: '',
        bgColor: null,
      ));
    }
  }

  void _onClearBackground(
    ClearBackground event,
    Emitter<DiaryEntryState> emit,
  ) {
    emit(
      state.copyWith(
        bgImage: '',
        bgGalleryImage: null,
        bgColor: null,
      ),
    );
  }

  void _onStickerAdded(StickerAdded event, Emitter<DiaryEntryState> emit) {
    final newSticker = StickerModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sticker: event.sticker,
      x: event.x,
      y: event.y,
    );
    emit(state.copyWith(
      stickers: [...state.stickers, newSticker],
      selectedStickerId: null,
      selectedImageId: null,
    ));
  }

  void _onUpdateStickerPosition(
    UpdateStickerPosition event,
    Emitter<DiaryEntryState> emit,
  ) {
    final updatedStickers = state.stickers.map((s) {
      if (s.id == event.id) return s.copyWith(x: event.x, y: event.y);
      return s;
    }).toList();
    emit(state.copyWith(stickers: updatedStickers));
  }

  void _onUpdateStickerSize(
    UpdateStickerSize event,
    Emitter<DiaryEntryState> emit,
  ) {
    final updatedStickers = state.stickers.map((s) {
      if (s.id == event.id) return s.copyWith(size: event.size);
      return s;
    }).toList();
    emit(state.copyWith(stickers: updatedStickers));
  }

  void _onUpdateStickerTransform(
    UpdateStickerTransform event,
    Emitter<DiaryEntryState> emit,
  ) {
    final updatedStickers = state.stickers.map((s) {
      if (s.id == event.id) {
        return s.copyWith(x: event.x, y: event.y, size: event.size);
      }
      return s;
    }).toList();
    emit(state.copyWith(stickers: updatedStickers));
  }

  void _onRemoveSticker(RemoveSticker event, Emitter<DiaryEntryState> emit) {
    final updatedStickers = state.stickers
        .where((s) => s.id != event.id)
        .toList();
    emit(state.copyWith(
      stickers: updatedStickers,
      selectedStickerId: null,
    ));
  }

  void _onImageAdded(ImageAdded event, Emitter<DiaryEntryState> emit) {
    final newImage = DiaryImage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: event.imagePath,
      x: event.x,
      y: event.y,
      width: 100,
      height: 100,
      scale: 1.0,
    );
    emit(state.copyWith(
      images: [...state.images, newImage],
      selectedStickerId: null,
      selectedImageId: null,
    ));
  }

  void _onUpdateImagePosition(
    UpdateImagePosition event,
    Emitter<DiaryEntryState> emit,
  ) {
    final updatedImages = state.images.map((image) {
      if (image.id == event.imageId) {
        return image.copyWith(x: event.x, y: event.y);
      }
      return image;
    }).toList();
    emit(state.copyWith(images: updatedImages));
  }

  void _onUpdateImageSize(
    UpdateImageSize event,
    Emitter<DiaryEntryState> emit,
  ) {
    final updatedImages = state.images.map((image) {
      if (image.id == event.imageId) {
        return image.copyWith(scale: event.scale);
      }
      return image;
    }).toList();
    emit(state.copyWith(images: updatedImages));
  }

  void _onUpdateImageTransform(
    UpdateImageTransform event,
    Emitter<DiaryEntryState> emit,
  ) {
    final updatedImages = state.images.map((image) {
      if (image.id == event.imageId) {
        return image.copyWith(x: event.x, y: event.y, scale: event.scale);
      }
      return image;
    }).toList();
    emit(state.copyWith(images: updatedImages));
  }

  void _onRemoveImage(RemoveImage event, Emitter<DiaryEntryState> emit) {
    final updatedImages = state.images
        .where((image) => image.id != event.imageId)
        .toList();
    emit(state.copyWith(
      images: updatedImages,
      selectedImageId: null,
    ));
  }
}