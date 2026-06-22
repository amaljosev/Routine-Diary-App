import 'dart:convert';
import 'dart:io';

/// Extracts all local file paths from a single diary DB row,
/// and can rewrite them to/from drive:: placeholders.
class ImagePathExtractor {
  // Columns that hold a single local file path directly.
  static const _singlePathColumns = [
    'image_path',
    'bg_gallery_image_path',
    'bg_local_path',
    'bg_image_path',
  ];

  /// Returns all unique local file paths found in the row.
  /// Only returns paths that actually exist on disk.
  static List<String> extractPaths(Map<String, Object?> row) {
    final paths = <String>{};

    // Single-path columns
    for (final col in _singlePathColumns) {
      final val = row[col];
      if (val is String && val.isNotEmpty && _isLocalPath(val)) {
        if (File(val).existsSync()) paths.add(val);
      }
    }

    // stickers JSON — localPath field
    final stickersJson = row['stickers'];
    if (stickersJson is String && stickersJson.isNotEmpty) {
      try {
        final list = jsonDecode(stickersJson) as List;
        for (final item in list) {
          final lp = (item as Map)['localPath'];
          if (lp is String && lp.isNotEmpty && _isLocalPath(lp)) {
            if (File(lp).existsSync()) paths.add(lp);
          }
        }
      } catch (_) {}
    }

    // images JSON — imagePath field
    final imagesJson = row['images'];
    if (imagesJson is String && imagesJson.isNotEmpty) {
      try {
        final list = jsonDecode(imagesJson) as List;
        for (final item in list) {
          final ip = (item as Map)['imagePath'];
          if (ip is String && ip.isNotEmpty && _isLocalPath(ip)) {
            if (File(ip).existsSync()) paths.add(ip);
          }
        }
      } catch (_) {}
    }

    return paths.toList();
  }

  /// Replaces every local path in the row with drive::DRIVE_FILE_ID.
  /// [pathToId] maps original local path → Drive file ID.
  static Map<String, Object?> encodePaths(
    Map<String, Object?> row,
    Map<String, String> pathToId,
  ) {
    final result = Map<String, Object?>.from(row);

    // Single-path columns
    for (final col in _singlePathColumns) {
      final val = result[col];
      if (val is String && pathToId.containsKey(val)) {
        result[col] = 'drive::${pathToId[val]}';
      }
    }

    // stickers JSON
    final stickersJson = result['stickers'];
    if (stickersJson is String && stickersJson.isNotEmpty) {
      try {
        final list = jsonDecode(stickersJson) as List;
        final updated = list.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          final lp = m['localPath'];
          if (lp is String && pathToId.containsKey(lp)) {
            m['localPath'] = 'drive::${pathToId[lp]}';
          }
          return m;
        }).toList();
        result['stickers'] = jsonEncode(updated);
      } catch (_) {}
    }

    // images JSON
    final imagesJson = result['images'];
    if (imagesJson is String && imagesJson.isNotEmpty) {
      try {
        final list = jsonDecode(imagesJson) as List;
        final updated = list.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          final ip = m['imagePath'];
          if (ip is String && pathToId.containsKey(ip)) {
            m['imagePath'] = 'drive::${pathToId[ip]}';
          }
          return m;
        }).toList();
        result['images'] = jsonEncode(updated);
      } catch (_) {}
    }

    return result;
  }

  /// Replaces every drive::ID placeholder with the actual restored local path.
  /// [idToPath] maps Drive file ID → new local path.
  static Map<String, Object?> decodePaths(
    Map<String, Object?> row,
    Map<String, String> idToPath,
  ) {
    final result = Map<String, Object?>.from(row);

    // Single-path columns
    for (final col in _singlePathColumns) {
      final val = result[col];
      if (val is String && val.startsWith('drive::')) {
        final id = val.substring(7);
        if (idToPath.containsKey(id)) result[col] = idToPath[id];
      }
    }

    // stickers JSON
    final stickersJson = result['stickers'];
    if (stickersJson is String && stickersJson.isNotEmpty) {
      try {
        final list = jsonDecode(stickersJson) as List;
        final updated = list.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          final lp = m['localPath'];
          if (lp is String && lp.startsWith('drive::')) {
            final id = lp.substring(7);
            if (idToPath.containsKey(id)) m['localPath'] = idToPath[id];
          }
          return m;
        }).toList();
        result['stickers'] = jsonEncode(updated);
      } catch (_) {}
    }

    // images JSON
    final imagesJson = result['images'];
    if (imagesJson is String && imagesJson.isNotEmpty) {
      try {
        final list = jsonDecode(imagesJson) as List;
        final updated = list.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          final ip = m['imagePath'];
          if (ip is String && ip.startsWith('drive::')) {
            final id = ip.substring(7);
            if (idToPath.containsKey(id)) m['imagePath'] = idToPath[id];
          }
          return m;
        }).toList();
        result['images'] = jsonEncode(updated);
      } catch (_) {}
    }

    return result;
  }

  /// Collects all drive::ID values from a restored row.
  static List<String> extractDriveIds(Map<String, Object?> row) {
    final ids = <String>{};

    for (final col in _singlePathColumns) {
      final val = row[col];
      if (val is String && val.startsWith('drive::')) {
        ids.add(val.substring(7));
      }
    }

    final stickersJson = row['stickers'];
    if (stickersJson is String && stickersJson.isNotEmpty) {
      try {
        final list = jsonDecode(stickersJson) as List;
        for (final item in list) {
          final lp = (item as Map)['localPath'];
          if (lp is String && lp.startsWith('drive::')) ids.add(lp.substring(7));
        }
      } catch (_) {}
    }

    final imagesJson = row['images'];
    if (imagesJson is String && imagesJson.isNotEmpty) {
      try {
        final list = jsonDecode(imagesJson) as List;
        for (final item in list) {
          final ip = (item as Map)['imagePath'];
          if (ip is String && ip.startsWith('drive::')) ids.add(ip.substring(7));
        }
      } catch (_) {}
    }

    return ids.toList();
  }

  static bool _isLocalPath(String path) =>
      path.startsWith('/') || path.startsWith('file://');
}