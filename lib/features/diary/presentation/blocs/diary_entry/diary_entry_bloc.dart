import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/data/repository/supabase_background_repository.dart';
import 'package:routine/features/diary/data/repository/supabase_sticker_repository.dart';
import 'package:routine/features/diary/domain/entities/sticker_model.dart';
import 'package:routine/features/diary/domain/repository/background_repository.dart';
import 'package:routine/features/diary/domain/repository/sticker_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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
    on<BackgroundDownloadCompleted>(_onBackgroundDownloadCompleted);
    on<BackgroundDownloadFailed>(_onBackgroundDownloadFailed);

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

  // ── Initialization ────────────────────────────────────────────────

  /// Populates the editor state from a saved [DiaryEntryModel].
  ///
  /// After emitting the base state, performs two recovery checks for entries
  /// that were restored from a Drive backup on a new device:
  ///
  /// 1. **Background recovery** — if `bgLocalPath` is null but `bgImagePath`
  ///    (the Supabase preset URL) is present, the local cached copy was not
  ///    restored (either because the file download failed or it was originally
  ///    a Supabase preset that was never uploaded to Drive). We re-download it
  ///    from Supabase so `bgLocalPath` is populated for rendering.
  ///
  /// 2. **Sticker recovery** — any sticker whose `localPath` is null (set to
  ///    null by [ImagePathExtractor.decodePaths] when its Drive download
  ///    failed, or that was never downloaded on the original device) is
  ///    re-downloaded from its Supabase `url` and its `localPath` is patched
  ///    in-place in the stickers list.
  Future<void> _onInitializeDiaryEntry(
    InitializeDiaryEntry event,
    Emitter<DiaryEntryState> emit,
  ) async {
    final e = event.entry;
    if (e == null) return;

    // ── Gallery background validation ─────────────────────────────
    String? bgGalleryImage = e.bgGalleryImagePath;
    if (bgGalleryImage != null && bgGalleryImage.isNotEmpty) {
      if (!File(bgGalleryImage).existsSync()) bgGalleryImage = null;
    }

    // ── Parse stickers ────────────────────────────────────────────
    List<StickerModel> stickers = [];
    if (e.stickersJson != null && e.stickersJson!.isNotEmpty) {
      try {
        final List<dynamic> stickerList = jsonDecode(e.stickersJson!);
        stickers = stickerList.map((s) => StickerModel.fromJson(s)).toList();
      } catch (_) {
        stickers = [];
      }
    }

    // ── Parse images ──────────────────────────────────────────────
    List<DiaryImage> images = [];
    if (e.imagesJson != null && e.imagesJson!.isNotEmpty) {
      try {
        final List<dynamic> imageList = jsonDecode(e.imagesJson!);
        images = imageList.map((i) => DiaryImage.fromJson(i)).toList();
      } catch (_) {
        images = [];
      }
    }

    // ── Emit base state ───────────────────────────────────────────
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

    // ── Recovery 1: background ────────────────────────────────────
    // bgLocalPath is null  → local file is missing (failed Drive restore, or
    //                         was a Supabase preset never cached locally).
    // bgImagePath is set   → we have a Supabase URL to re-download from.
    //
    // We also check bgLocalPath against the file system: it's possible the
    // path is non-null but the file was deleted (e.g. app reinstall).
    final needsBgRecovery = _needsBackgroundRecovery(e);
    if (needsBgRecovery && e.bgImagePath != null && e.bgImagePath!.isNotEmpty) {
      add(DownloadBackground(e.bgImagePath!));
    }

    // ── Recovery 2: stickers ──────────────────────────────────────
    // Any sticker with localPath == null or a path that no longer exists on
    // disk needs to be re-fetched from Supabase using its `url`.
    for (final sticker in stickers) {
      if (_needsStickerRecovery(sticker)) {
        add(DownloadSticker(sticker.url));
      }
    }
  }

  /// Returns true if the background local file is missing and must be
  /// re-downloaded from Supabase.
  bool _needsBackgroundRecovery(DiaryEntryModel e) {
    // No Supabase preset URL → nothing to recover from.
    if (e.bgImagePath == null || e.bgImagePath!.isEmpty) return false;

    // bgLocalPath is null → definitely missing.
    if (e.bgLocalPath == null || e.bgLocalPath!.isEmpty) return true;

    // bgLocalPath is set but file no longer exists on this device.
    return !File(e.bgLocalPath!).existsSync();
  }

  /// Returns true if the sticker's local file is missing and must be
  /// re-downloaded from Supabase.
  bool _needsStickerRecovery(StickerModel sticker) {
    // No Supabase URL → nothing to recover from.
    if (sticker.url.isEmpty) return false;

    // localPath is null → definitely missing.
    if (sticker.localPath == null || sticker.localPath!.isEmpty) return true;

    // localPath is set but file no longer exists on this device.
    return !File(sticker.localPath!).existsSync();
  }

  // ── Color parsing ─────────────────────────────────────────────────

  Color? _parseColorFromString(String? input) {
    if (input == null || input.isEmpty) return null;
    final String s = input.trim();

    final colorRegex = RegExp(r'^Color\(0x([0-9a-fA-F]{8})\)$');
    final match = colorRegex.firstMatch(s);
    if (match != null) {
      final hex = match.group(1);
      if (hex != null) return Color(int.parse(hex, radix: 16));
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

  // ── Background handlers ───────────────────────────────────────────

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
      final sourcePath = croppedFile?.path ?? event.imagePath;
      final permanentPath = await _copyImageToPermanentStorage(sourcePath);
      emit(
        state.copyWith(
          bgGalleryImage: permanentPath,
          bgImage: '',
          bgColor: null,
          bgLocalPath: null,
        ),
      );
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

  /// Downloads a Supabase background and updates [bgLocalPath].
  ///
  /// Used both when the user picks a new preset background AND during
  /// [_onInitializeDiaryEntry] recovery (when bgLocalPath is missing after
  /// a Drive restore). On success the bgImage (Supabase URL) is preserved in
  /// state via [BackgroundDownloadCompleted] so the DB retains it for future
  /// recovery attempts.
  Future<void> _onDownloadBackground(
    DownloadBackground event,
    Emitter<DiaryEntryState> emit,
  ) async {
    emit(state.copyWith(isDownloadingBackground: true, downloadError: null));
    try {
      final localPath = await _backgroundRepo.downloadBackground(event.url);
      add(BackgroundDownloadCompleted(event.url, localPath));
    } catch (e) {
      add(BackgroundDownloadFailed(event.url, e.toString()));
    }
  }

  /// Applies a successfully downloaded background.
  ///
  /// Stores both [bgImage] (the Supabase URL, kept for future recovery) and
  /// [bgLocalPath] (the local cached file used for rendering). This way if
  /// the entry is backed up and restored again, [_needsBackgroundRecovery]
  /// can use bgImagePath to re-download.
  void _onBackgroundDownloadCompleted(
    BackgroundDownloadCompleted event,
    Emitter<DiaryEntryState> emit,
  ) {
    emit(
      state.copyWith(
        isDownloadingBackground: false,
        downloadError: null,
        bgImage: event.url, // ← Supabase URL retained for recovery
        bgLocalPath: event.localPath,
        bgColor: null,
        bgGalleryImage: null,
      ),
    );
  }

  void _onBackgroundDownloadFailed(
    BackgroundDownloadFailed event,
    Emitter<DiaryEntryState> emit,
  ) {
    emit(
      state.copyWith(
        isDownloadingBackground: false,
        downloadError: 'Background unavailable. Please try again later.',
      ),
    );
  }

  // ── Sticker handlers ──────────────────────────────────────────────

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

  /// Downloads a sticker from Supabase.
  ///
  /// Used both when the user picks a sticker from the picker AND during
  /// [_onInitializeDiaryEntry] recovery (when a sticker's localPath is null
  /// after a Drive restore). On [StickerDownloadCompleted] the localPath is
  /// patched into every matching sticker in the current stickers list so the
  /// UI renders it immediately without needing a full reload.
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

  /// Patches [localPath] into every sticker whose [url] matches the
  /// completed download.
  ///
  /// This covers the recovery case: multiple stickers in one entry can share
  /// the same Supabase URL (e.g. the user added the same sticker twice), so
  /// we update all of them at once.
  void _onStickerDownloadCompleted(
    StickerDownloadCompleted event,
    Emitter<DiaryEntryState> emit,
  ) {
    final updatedStickers = state.stickers.map((s) {
      if (s.url == event.url &&
          (s.localPath == null || !File(s.localPath!).existsSync())) {
        return s.copyWith(localPath: event.localPath);
      }
      return s;
    }).toList();

    emit(
      state.copyWith(
        stickers: updatedStickers,
        isDownloadingSticker: false,
        stickerDownloadError: null,
      ),
    );
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

  // ── Image (diary_images) handlers ─────────────────────────────────

  Future<void> _onImageAdded(
    ImageAdded event,
    Emitter<DiaryEntryState> emit,
  ) async {
    try {
      final permanentPath = await _copyImageToPermanentStorage(event.imagePath);

      // Decode actual image dimensions to preserve aspect ratio.
      final bytes = await File(permanentPath).readAsBytes();
      final codec = await instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final imageWidth = frameInfo.image.width.toDouble();
      final imageHeight = frameInfo.image.height.toDouble();

      // Scale down to a reasonable starting size (max 200px on longest side).
      const maxSize = 200.0;
      final scaleFactor = imageWidth >= imageHeight
          ? maxSize / imageWidth
          : maxSize / imageHeight;
      final displayW = imageWidth * scaleFactor;
      final displayH = imageHeight * scaleFactor;

      final newImage = DiaryImage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: permanentPath,
        x: event.x,
        y: event.y,
        width: displayW,
        height: displayH,
        scale: 1.0,
      );

      emit(
        state.copyWith(
          images: [...state.images, newImage],
          selectedStickerId: null,
          selectedImageId: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to add image: $e'));
    }
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

  // ── Utilities ─────────────────────────────────────────────────────

  /// Copies [sourcePath] into the app's permanent `diary_images/` directory.
  Future<String> _copyImageToPermanentStorage(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final diaryImagesDir = Directory('${appDir.path}/diary_images');
    if (!diaryImagesDir.existsSync()) {
      diaryImagesDir.createSync(recursive: true);
    }
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${sourcePath.split('/').last}';
    final destination = '${diaryImagesDir.path}/$fileName';
    await File(sourcePath).copy(destination);
    return destination;
  }
}
