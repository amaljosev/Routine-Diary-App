import 'dart:convert';
import 'dart:io';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/data/repository/supabase_background_repository.dart';
import 'package:routine/features/diary/data/repository/supabase_sticker_repository.dart';
import 'package:routine/features/diary/domain/entities/sticker_model.dart';
import 'package:routine/features/diary/domain/repository/background_repository.dart';
import 'package:routine/features/diary/domain/repository/sticker_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

part 'diary_entry_event.dart';
part 'diary_entry_state.dart';

class DiaryEntryBloc extends Bloc<DiaryEntryEvent, DiaryEntryState> {
  final BackgroundRepository _backgroundRepo = SupabaseBackgroundRepository();
  final StickerRepository _stickerRepo = SupabaseStickerRepository();

  // Base font size used for stickers (applied in the UI)
  static const double kBaseStickerFontSize = 40.0;

  DiaryEntryBloc() : super(DiaryEntryState(date: DateTime.now())) {
    on<InitializeDiaryEntry>(_onInitializeDiaryEntry);
    on<TitleChanged>((event, emit) => emit(state.copyWith(title: event.title)));
    on<DescriptionChanged>(
      (event, emit) => emit(state.copyWith(description: event.description)),
    );
    on<MoodChanged>((event, emit) => emit(state.copyWith(mood: event.mood)));
    on<DateChanged>((event, emit) => emit(state.copyWith(date: event.date)));
    on<FontChanged>(
      (event, emit) => emit(state.copyWith(fontFamily: event.fontFamily)),
    );
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

    // Background events
    on<LoadBackgrounds>(_onLoadBackgrounds);
    on<BackgroundsLoaded>(_onBackgroundsLoaded);
    on<BackgroundsLoadFailed>(_onBackgroundsLoadFailed);
    on<SelectSupabaseBackground>(_onSelectSupabaseBackground);
    on<DownloadBackground>(_onDownloadBackground);

    // Sticker events
    on<LoadStickers>(_onLoadStickers);
    on<StickersByCategoryLoaded>(_onStickersByCategoryLoaded);
    on<StickersLoaded>(_onStickersLoaded);
    on<StickersLoadFailed>(_onStickersLoadFailed);
    on<SelectSupabaseSticker>(_onSelectSupabaseSticker);
    on<DownloadSticker>(_onDownloadSticker);
    on<StickerDownloadCompleted>(_onStickerDownloadCompleted);
    on<StickerDownloadFailed>(_onStickerDownloadFailed);

    on<SelectSticker>((event, emit) {
      emit(state.copyWith(selectedStickerId: event.id, selectedImageId: null));
    });
    on<SelectImage>((event, emit) {
      emit(state.copyWith(selectedImageId: event.id, selectedStickerId: null));
    });
    on<DeselectAll>((event, emit) {
      emit(state.copyWith(selectedStickerId: null, selectedImageId: null));
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
      String? bgGalleryImage = e.bgGalleryImagePath;

      if (bgGalleryImage != null && bgGalleryImage.isNotEmpty) {
        final file = File(bgGalleryImage);
        if (!file.existsSync()) {
          bgGalleryImage = null;
        }
      }

      // Parse stickers (new format: url, localPath)
      List<StickerModel> stickers = [];
      if (e.stickersJson != null && e.stickersJson!.isNotEmpty) {
        try {
          final List<dynamic> stickerList = jsonDecode(e.stickersJson!);
          stickers = stickerList.map((s) {
            final sticker = StickerModel.fromJson(s);
            // Optional: convert legacy sizes if needed
            return sticker;
          }).toList();
        } catch (_) {
          stickers = [];
        }
      }

      // Parse images
      List<DiaryImage> images = [];
      if (e.imagesJson != null && e.imagesJson!.isNotEmpty) {
        try {
          final List<dynamic> imageList = jsonDecode(e.imagesJson!);
          images = imageList.map((i) => DiaryImage.fromJson(i)).toList();
        } catch (_) {
          images = [];
        }
      }

      emit(
        state.copyWith(
          title: e.title,
          description: e.content,
          mood: e.mood,
          fontFamily: e.fontFamily,
          bgColor: _parseColorFromString(e.bgColor),
          bgGalleryImage: bgGalleryImage,
          stickers: stickers,
          images: images,
          date: DateTime.tryParse(e.date) ?? DateTime.now(),
          bgImage: e.bgImagePath ?? '',
          bgLocalPath: e.bgLocalPath,
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

    if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(s)) {
      return Color(int.parse(s, radix: 16));
    }

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
        bgLocalPath: null,
      ),
    );
  }

  void _onBgImageChanged(BgImageChanged event, Emitter<DiaryEntryState> emit) {
    emit(
      state.copyWith(
        bgImage: event.image,
        bgColor: null,
        bgGalleryImage: null,
        bgLocalPath: null,
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
        bgLocalPath: null,
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
          IOSUiSettings(title: 'Crop Background', aspectRatioLockEnabled: true),
        ],
      );

      if (croppedFile != null) {
        emit(
          state.copyWith(
            bgGalleryImage: croppedFile.path,
            bgImage: '',
            bgColor: null,
            bgLocalPath: null,
          ),
        );
      } else {
        emit(
          state.copyWith(
            bgGalleryImage: event.imagePath,
            bgImage: '',
            bgColor: null,
            bgLocalPath: null,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to crop image: $e',
          bgGalleryImage: event.imagePath,
          bgImage: '',
          bgColor: null,
          bgLocalPath: null,
        ),
      );
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
        bgLocalPath: null,
      ),
    );
  }

  // Sticker handlers
  void _onStickerAdded(StickerAdded event, Emitter<DiaryEntryState> emit) {
    final newSticker = StickerModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: event.url,
      localPath: event.localPath,
      x: event.x,
      y: event.y,
      size: 1.0,
    );
    emit(
      state.copyWith(
        stickers: [...state.stickers, newSticker],
        selectedStickerId: null,
        selectedImageId: null,
      ),
    );
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
        return s.copyWith(
          x: event.x,
          y: event.y,
          size: event.size,
          rotation: event.rotation,
        );
      }
      return s;
    }).toList();
    emit(state.copyWith(stickers: updatedStickers));
  }

  void _onRemoveSticker(RemoveSticker event, Emitter<DiaryEntryState> emit) {
    final updatedStickers = state.stickers
        .where((s) => s.id != event.id)
        .toList();
    emit(state.copyWith(stickers: updatedStickers, selectedStickerId: null));
  }

  // Image handlers
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
    emit(
      state.copyWith(
        images: [...state.images, newImage],
        selectedStickerId: null,
        selectedImageId: null,
      ),
    );
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
        return image.copyWith(
          x: event.x,
          y: event.y,
          scale: event.scale,
          rotation: event.rotation,
        );
      }
      return image;
    }).toList();
    emit(state.copyWith(images: updatedImages));
  }

  void _onRemoveImage(RemoveImage event, Emitter<DiaryEntryState> emit) {
    final updatedImages = state.images
        .where((image) => image.id != event.imageId)
        .toList();
    emit(state.copyWith(images: updatedImages, selectedImageId: null));
  }

  // Background methods
  Future<void> _onLoadBackgrounds(
    LoadBackgrounds event,
    Emitter<DiaryEntryState> emit,
  ) async {
    emit(state.copyWith(isLoadingBackgrounds: true, backgroundsError: null));
    try {
      final urls = await _backgroundRepo.getBackgroundUrls();
      add(BackgroundsLoaded(urls));
    } catch (e) {
      add(BackgroundsLoadFailed(e.toString()));
    }
  }

  void _onBackgroundsLoaded(
    BackgroundsLoaded event,
    Emitter<DiaryEntryState> emit,
  ) {
    emit(
      state.copyWith(
        availableBackgrounds: event.urls,
        isLoadingBackgrounds: false,
      ),
    );
  }

  void _onBackgroundsLoadFailed(
    BackgroundsLoadFailed event,
    Emitter<DiaryEntryState> emit,
  ) {
    emit(
      state.copyWith(
        isLoadingBackgrounds: false,
        backgroundsError: event.error,
      ),
    );
  }

  void _onSelectSupabaseBackground(
    SelectSupabaseBackground event,
    Emitter<DiaryEntryState> emit,
  ) {
    add(DownloadBackground(event.imageUrl));
  }

  Future<void> _onDownloadBackground(
    DownloadBackground event,
    Emitter<DiaryEntryState> emit,
  ) async {
    emit(state.copyWith(isDownloadingBackground: true, downloadError: null));
    try {
      final localPath = await _backgroundRepo.downloadBackground(event.url);
      emit(
        state.copyWith(
          isDownloadingBackground: false,
          bgImage: event.url,
          bgLocalPath: localPath,
          bgColor: null,
          bgGalleryImage: null,
        ),
      );
    } catch (e) {
      // Don't touch bgImage or bgLocalPath — leave background unchanged
      emit(
        state.copyWith(
          isDownloadingBackground: false,
          downloadError: 'Background unavailable. Please try again later.',
        ),
      );
    }
  }

  // Sticker Supabase methods
  Future<void> _onLoadStickers(
    LoadStickers event,
    Emitter<DiaryEntryState> emit,
  ) async {
    emit(state.copyWith(isLoadingStickers: true, stickersError: null));
    try {
      final map = await _stickerRepo.getStickersByCategory();
      add(StickersByCategoryLoaded(map));
    } catch (e) {
      add(StickersLoadFailed(e.toString()));
    }
  }

  void _onStickersByCategoryLoaded(
    StickersByCategoryLoaded event,
    Emitter<DiaryEntryState> emit,
  ) {
    emit(
      state.copyWith(
        stickersByCategory: event.stickersByCategory,
        isLoadingStickers: false,
      ),
    );
  }

  void _onStickersLoaded(StickersLoaded event, Emitter<DiaryEntryState> emit) {
    emit(
      state.copyWith(availableStickers: event.urls, isLoadingStickers: false),
    );
  }

  void _onStickersLoadFailed(
    StickersLoadFailed event,
    Emitter<DiaryEntryState> emit,
  ) {
    emit(state.copyWith(isLoadingStickers: false, stickersError: event.error));
  }

  Future<void> _onSelectSupabaseSticker(
    SelectSupabaseSticker event,
    Emitter<DiaryEntryState> emit,
  ) async {
    emit(
      state.copyWith(isDownloadingSticker: true, stickerDownloadError: null),
    );
    try {
      final localPath = await _stickerRepo.downloadSticker(event.stickerUrl);
      final newSticker = StickerModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: event.stickerUrl,
        localPath: localPath,
        x: event.x,
        y: event.y,
        size: 1.0,
      );
      emit(
        state.copyWith(
          stickers: [...state.stickers, newSticker],
          isDownloadingSticker: false,
          selectedStickerId: null,
          selectedImageId: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isDownloadingSticker: false,
          stickerDownloadError: e.toString(),
        ),
      );
      add(SetError('Failed to download sticker: $e'));
    }
  }

  Future<void> _onDownloadSticker(
    DownloadSticker event,
    Emitter<DiaryEntryState> emit,
  ) async {
    emit(
      state.copyWith(isDownloadingSticker: true, stickerDownloadError: null),
    );
    try {
      final localPath = await _stickerRepo.downloadSticker(event.url);
      add(StickerDownloadCompleted(event.url, localPath));
    } catch (e) {
      add(StickerDownloadFailed(event.url, e.toString()));
    }
  }

  void _onStickerDownloadCompleted(
    StickerDownloadCompleted event,
    Emitter<DiaryEntryState> emit,
  ) {
    emit(state.copyWith(isDownloadingSticker: false));
    // Optionally add the sticker automatically after download
    // You can emit an event here or let the UI handle it via onSelected.
  }

  void _onStickerDownloadFailed(
    StickerDownloadFailed event,
    Emitter<DiaryEntryState> emit,
  ) {
    emit(
      state.copyWith(
        isDownloadingSticker: false,
        stickerDownloadError: event.error,
      ),
    );
  }
}
