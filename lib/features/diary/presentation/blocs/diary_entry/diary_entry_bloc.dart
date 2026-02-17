import 'dart:convert';
import 'package:routine/core/utils/converters.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/domain/entities/sticker_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'diary_entry_event.dart';
part 'diary_entry_state.dart';

class DiaryEntryBloc extends Bloc<DiaryEntryEvent, DiaryEntryState> {
  DiaryEntryBloc() : super(DiaryEntryState()) {
    on<InitializeDiaryEntry>((event, emit) {
      final e = event.entry;

      if (e != null) {
        emit(
          state.copyWith(
            title: e.title,
            description: e.content,
            mood: e.mood,
            bgColor: e.bgColor is String
                ? AppConverters.stringToColorDiary(e.bgColor)
                : e.bgColor as Color?,
            bgImage: e.bgImagePath ?? '',
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
    });

    on<TitleChanged>((event, emit) => emit(state.copyWith(title: event.title)));
    on<DescriptionChanged>(
      (event, emit) => emit(state.copyWith(description: event.description)),
    );
    on<MoodChanged>((event, emit) => emit(state.copyWith(mood: event.mood)));
    on<DateChanged>((event, emit) => emit(state.copyWith(date: event.date)));
    on<BgColorChanged>(
      (event, emit) => emit(state.copyWith(bgColor: event.color, bgImage: '')),
    );
    on<BgImageChanged>(
      (event, emit) =>
          emit(state.copyWith(bgImage: event.image, bgColor: null)),
    );
    on<StickerAdded>((event, emit) {
      final newSticker = StickerModel(
        id: DateTime.now().toString(),
        sticker: event.sticker,
        x: event.x, 
        y: event.y, 
      );
      emit(state.copyWith(stickers: [...state.stickers, newSticker]));
    });

    on<BulletInserted>(
      (event, emit) =>
          emit(state.copyWith(description: '${state.description}\n• ')),
    );

    on<UpdateStickerPosition>((event, emit) {
      final updatedStickers = state.stickers.map((s) {
        if (s.id == event.id) return s.copyWith(x: event.x, y: event.y);
        return s;
      }).toList();
      emit(state.copyWith(stickers: updatedStickers));
    });
    on<UpdateStickerSize>((event, emit) {
      final updatedStickers = state.stickers.map((s) {
        if (s.id == event.id) return s.copyWith(size: event.size);
        return s;
      }).toList();
      emit(state.copyWith(stickers: updatedStickers));
    });
    on<RemoveSticker>((event, emit) {
      final updatedStickers = state.stickers
          .where((s) => s.id != event.id)
          .toList();
      emit(state.copyWith(stickers: updatedStickers));
    });

    on<ImageAdded>((event, emit) {
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
    });
    on<UpdateImagePosition>((event, emit) {
      final updatedImages = state.images.map((image) {
        if (image.id == event.imageId) {
          return image.copyWith(x: event.x, y: event.y);
        }
        return image;
      }).toList();
      emit(state.copyWith(images: updatedImages));
    });
    on<UpdateImageSize>((event, emit) {
      final updatedImages = state.images.map((image) {
        if (image.id == event.imageId) {
          return image.copyWith(scale: event.scale);
        }
        return image;
      }).toList();
      emit(state.copyWith(images: updatedImages));
    });
    on<RemoveImage>((event, emit) {
      final updatedImages = state.images
          .where((image) => image.id != event.imageId)
          .toList();
      emit(state.copyWith(images: updatedImages));
    });
    on<SelectSticker>((event, emit) {
      emit(state.copyWith(selectedStickerId: event.id, selectedImageId: null));
    });
    on<SelectImage>((event, emit) {
      emit(state.copyWith(selectedImageId: event.id, selectedStickerId: null));
    });
    on<DeselectAll>((event, emit) {
      emit(state.copyWith(selectedStickerId: '', selectedImageId: ''));
    });
  }
}
