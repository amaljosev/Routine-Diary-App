part of 'diary_entry_bloc.dart';

const unset = Object();

// Inside diary_entry_state.dart, replace the DiaryImage class with this:

class DiaryImage extends Equatable {
  final String id;
  final String imagePath;
  final double x;
  final double y;
  final double width;
  final double height;
  final double scale;
  final double rotation; // new field

  const DiaryImage({
    required this.id,
    required this.imagePath,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.scale,
    this.rotation = 0.0,
  });

  DiaryImage copyWith({
    String? id,
    String? imagePath,
    double? x,
    double? y,
    double? width,
    double? height,
    double? scale,
    double? rotation,
  }) {
    return DiaryImage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'scale': scale,
      'rotation': rotation,
    };
  }

  factory DiaryImage.fromJson(Map<String, dynamic> json) {
    return DiaryImage(
      id: json['id'],
      imagePath: json['imagePath'],
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
      scale: json['scale'].toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, imagePath, x, y, width, height, scale, rotation];
}

class DiaryEntryState extends Equatable {
  final String title;
  final String description;
  final String mood;
  final Color? bgColor;
  final String bgImage;
  final String? bgGalleryImage;
  final String? bgLocalPath;
  final List<StickerModel> stickers;
  final List<DiaryImage> images;
  final DateTime date;
  final String? selectedStickerId;
  final String? selectedImageId;
  final String? errorMessage;
  final List<String> availableBackgrounds;
  final bool isLoadingBackgrounds;
  final String? backgroundsError;
  final bool isDownloadingBackground;
  final String? downloadError;
  final String? fontFamily;

  const DiaryEntryState({
    this.title = '',
    this.description = '',
    this.mood = '😊',
    this.bgColor,
    this.bgImage = '',
    this.bgGalleryImage,
    this.bgLocalPath,
    this.stickers = const [],
    this.images = const [],
    required this.date,
    this.selectedStickerId,
    this.selectedImageId,
    this.errorMessage,
    this.availableBackgrounds = const [],
    this.isLoadingBackgrounds = false,
    this.backgroundsError,
    this.isDownloadingBackground = false,
    this.downloadError,
    this.fontFamily,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    mood,
    bgColor,
    bgImage,
    bgGalleryImage,
    bgLocalPath,
    stickers,
    images,
    date,
    selectedStickerId,
    selectedImageId,
    errorMessage,
    availableBackgrounds,
    isLoadingBackgrounds,
    backgroundsError,
    isDownloadingBackground,
    downloadError,
    fontFamily,
  ];

  DiaryEntryState copyWith({
    Object? title = unset,
    Object? description = unset,
    Object? mood = unset,
    Object? bgColor = unset,
    Object? bgImage = unset,
    Object? bgGalleryImage = unset,
    Object? bgLocalPath = unset,
    Object? stickers = unset,
    Object? images = unset,
    Object? date = unset,
    Object? selectedStickerId = unset,
    Object? selectedImageId = unset,
    Object? errorMessage = unset,
    List<String>? availableBackgrounds,
    bool? isLoadingBackgrounds,
    String? backgroundsError,
    bool? isDownloadingBackground,
    String? downloadError,
    Object? fontFamily = unset,
  }) {
    return DiaryEntryState(
      title: title == unset ? this.title : title as String,
      description: description == unset
          ? this.description
          : description as String,
      mood: mood == unset ? this.mood : mood as String,
      bgColor: bgColor == unset ? this.bgColor : bgColor as Color?,
      bgImage: bgImage == unset ? this.bgImage : bgImage as String,
      bgGalleryImage: bgGalleryImage == unset
          ? this.bgGalleryImage
          : bgGalleryImage as String?,
      bgLocalPath: bgLocalPath == unset
          ? this.bgLocalPath
          : bgLocalPath as String?,
      stickers: stickers == unset
          ? this.stickers
          : stickers as List<StickerModel>,
      images: images == unset ? this.images : images as List<DiaryImage>,
      date: date == unset ? this.date : date as DateTime,
      selectedStickerId: selectedStickerId == unset
          ? this.selectedStickerId
          : selectedStickerId as String?,
      selectedImageId: selectedImageId == unset
          ? this.selectedImageId
          : selectedImageId as String?,
      errorMessage: errorMessage == unset
          ? this.errorMessage
          : errorMessage as String?,
      availableBackgrounds: availableBackgrounds ?? this.availableBackgrounds,
      isLoadingBackgrounds: isLoadingBackgrounds ?? this.isLoadingBackgrounds,
      backgroundsError: backgroundsError ?? this.backgroundsError,
      isDownloadingBackground:
          isDownloadingBackground ?? this.isDownloadingBackground,
      downloadError: downloadError ?? this.downloadError,
      fontFamily: fontFamily == unset ? this.fontFamily : fontFamily as String?,
    );
  }
}
