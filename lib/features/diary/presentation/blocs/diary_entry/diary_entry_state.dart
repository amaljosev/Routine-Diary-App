part of 'diary_entry_bloc.dart';

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
  final String selectedStickerId;
  final String selectedImageId;

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
    this.selectedStickerId = '',
    this.selectedImageId = '',
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
      ];

  DiaryEntryState copyWith({
    String? title,
    String? description,
    String? mood,
    Color? bgColor,
    String? bgImage,
    String? bgGalleryImage,
    List<StickerModel>? stickers,
    List<DiaryImage>? images,
    DateTime? date,
    String? selectedStickerId,
    String? selectedImageId,
  }) {
    return DiaryEntryState(
      title: title ?? this.title,
      description: description ?? this.description,
      mood: mood ?? this.mood,
      bgColor: bgColor ?? this.bgColor,
      bgImage: bgImage ?? this.bgImage,
      bgGalleryImage: bgGalleryImage, 
      stickers: stickers ?? this.stickers,
      images: images ?? this.images,
      date: date ?? this.date,
      selectedStickerId: selectedStickerId ?? this.selectedStickerId,
      selectedImageId: selectedImageId ?? this.selectedImageId,
    );
  }
}