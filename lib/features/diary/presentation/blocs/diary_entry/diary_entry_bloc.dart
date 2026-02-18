import 'dart:convert';
import 'dart:io';
import 'package:routine/core/utils/converters.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/domain/entities/sticker_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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
    on<StickerAdded>(_onStickerAdded);
    on<BulletInserted>(
      (event, emit) =>
          emit(state.copyWith(description: '${state.description}\n• ')),
    );
    on<UpdateStickerPosition>(_onUpdateStickerPosition);
    on<UpdateStickerSize>(_onUpdateStickerSize);
    on<RemoveSticker>(_onRemoveSticker);
    on<ImageAdded>(_onImageAdded);
    on<UpdateImagePosition>(_onUpdateImagePosition);
    on<UpdateImageSize>(_onUpdateImageSize);
    on<RemoveImage>(_onRemoveImage);
    on<SelectSticker>((event, emit) {
      emit(state.copyWith(selectedStickerId: event.id, selectedImageId: null));
    });
    on<SelectImage>((event, emit) {
      emit(state.copyWith(selectedImageId: event.id, selectedStickerId: null));
    });
    on<DeselectAll>((event, emit) {
      emit(state.copyWith(selectedStickerId: '', selectedImageId: ''));
    });
    on<ClearBackground>(_onClearBackground);
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
          bgColor: e.bgColor is String
              ? AppConverters.stringToColorDiary(e.bgColor)
              : e.bgColor as Color?,
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

  void _onBgColorChanged(BgColorChanged event, Emitter<DiaryEntryState> emit) {
    emit(
      state.copyWith(
        bgColor: event.color,
        bgImage: '', // Clear asset image
        bgGalleryImage: null, // Clear gallery image
      ),
    );
  }

  void _onBgImageChanged(BgImageChanged event, Emitter<DiaryEntryState> emit) {
    emit(
      state.copyWith(
        bgImage: event.image,
        bgColor: null, // Clear color
        bgGalleryImage: null, // Clear gallery image
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
        bgImage: '', // Clear asset image
        bgColor: null, // Clear color
      ),
    );
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
      id: DateTime.now().toString(),
      sticker: event.sticker,
      x: event.x,
      y: event.y,
    );
    emit(state.copyWith(stickers: [...state.stickers, newSticker]));
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

  void _onRemoveSticker(RemoveSticker event, Emitter<DiaryEntryState> emit) {
    final updatedStickers = state.stickers
        .where((s) => s.id != event.id)
        .toList();
    emit(state.copyWith(stickers: updatedStickers));
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
    emit(state.copyWith(images: [...state.images, newImage]));
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

  void _onRemoveImage(RemoveImage event, Emitter<DiaryEntryState> emit) {
    final updatedImages = state.images
        .where((image) => image.id != event.imageId)
        .toList();
    emit(state.copyWith(images: updatedImages));
  }
}