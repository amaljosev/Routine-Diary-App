part of 'diary_entry_bloc.dart';

// Sentinel value to represent "no change" in copyWith
const unset = Object();

class DiaryImage extends Equatable {
  final String id;
  final String imagePath;
  final double x;
  final double y;
  final double width;
  final double height;
  final double scale;

  const DiaryImage({
    required this.id,
    required this.imagePath,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.scale,
  });

  DiaryImage copyWith({
    String? id,
    String? imagePath,
    double? x,
    double? y,
    double? width,
    double? height,
    double? scale,
  }) {
    return DiaryImage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      scale: scale ?? this.scale,
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
    );
  }

  @override
  List<Object?> get props => [id, imagePath, x, y, width, height, scale];
}

class DiaryEntryState extends Equatable {
  final String title;
  final String description;
  final String mood;
  final Color? bgColor;
  final String bgImage;
  final String? bgGalleryImage;
  final List<StickerModel> stickers;
  final List<DiaryImage> images;
  final DateTime date;
  final String? selectedStickerId;
  final String? selectedImageId;
  final String? errorMessage;

  const DiaryEntryState({
    this.title = '',
    this.description = '',
    this.mood = '😊',
    this.bgColor,
    this.bgImage = '',
    this.bgGalleryImage,
    this.stickers = const [],
    this.images = const [],
    required this.date,
    this.selectedStickerId,
    this.selectedImageId,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        mood,
        bgColor,
        bgImage,
        bgGalleryImage,
        stickers,
        images,
        date,
        selectedStickerId,
        selectedImageId,
        errorMessage,
      ];

  DiaryEntryState copyWith({
    Object? title = unset,
    Object? description = unset,
    Object? mood = unset,
    Object? bgColor = unset,
    Object? bgImage = unset,
    Object? bgGalleryImage = unset,
    Object? stickers = unset,
    Object? images = unset,
    Object? date = unset,
    Object? selectedStickerId = unset,
    Object? selectedImageId = unset,
    Object? errorMessage = unset,
  }) {
    return DiaryEntryState(
      title: title == unset ? this.title : title as String,
      description: description == unset ? this.description : description as String,
      mood: mood == unset ? this.mood : mood as String,
      bgColor: bgColor == unset ? this.bgColor : bgColor as Color?,
      bgImage: bgImage == unset ? this.bgImage : bgImage as String,
      bgGalleryImage: bgGalleryImage == unset ? this.bgGalleryImage : bgGalleryImage as String?,
      stickers: stickers == unset ? this.stickers : stickers as List<StickerModel>,
      images: images == unset ? this.images : images as List<DiaryImage>,
      date: date == unset ? this.date : date as DateTime,
      selectedStickerId: selectedStickerId == unset ? this.selectedStickerId : selectedStickerId as String?,
      selectedImageId: selectedImageId == unset ? this.selectedImageId : selectedImageId as String?,
      errorMessage: errorMessage == unset ? this.errorMessage : errorMessage as String?,
    );
  }
}