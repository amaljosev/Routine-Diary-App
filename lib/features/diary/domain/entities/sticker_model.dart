import 'package:equatable/equatable.dart';

class StickerModel extends Equatable {
  final String id;
  final String url;               
  final String? localPath;         
  final double x;
  final double y;
  final double size;
  final double rotation;

  const StickerModel({
    required this.id,
    required this.url,
    this.localPath,
    required this.x,
    required this.y,
    this.size = 1.0,
    this.rotation = 0.0,
  });

  StickerModel copyWith({
    String? id,
    String? url,
    String? localPath,
    double? x,
    double? y,
    double? size,
    double? rotation,
  }) {
    return StickerModel(
      id: id ?? this.id,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      x: x ?? this.x,
      y: y ?? this.y,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'localPath': localPath,
    'x': x,
    'y': y,
    'size': size,
    'rotation': rotation,
  };

  factory StickerModel.fromJson(Map<String, dynamic> json) {
    return StickerModel(
      id: json['id'],
      url: json['url'],
      localPath: json['localPath'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      size: (json['size'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, url, localPath, x, y, size, rotation];
}