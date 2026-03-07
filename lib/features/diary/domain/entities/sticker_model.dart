import 'package:equatable/equatable.dart';

class StickerModel extends Equatable {
  final String id;
  final String sticker;
  final double x;
  final double y;
  final double size;
  final double rotation;

  const StickerModel({
    required this.id,
    required this.sticker,
    required this.x,
    required this.y,
    this.size = 28,
    this.rotation = 0.0,
  });

  StickerModel copyWith({
    String? id,
    String? sticker,
    double? x,
    double? y,
    double? size,
    double? rotation,
  }) {
    return StickerModel(
      id: id ?? this.id,
      sticker: sticker ?? this.sticker,
      x: x ?? this.x,
      y: y ?? this.y,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sticker': sticker,
    'x': x,
    'y': y,
    'size': size,
    'rotation': rotation,
  };

  factory StickerModel.fromJson(Map<String, dynamic> json) {
    return StickerModel(
      id: json['id'],
      sticker: json['sticker'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      size: (json['size'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, sticker, x, y, size, rotation];
}
