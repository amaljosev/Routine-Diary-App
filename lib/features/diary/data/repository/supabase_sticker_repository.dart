import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:routine/features/diary/domain/repository/sticker_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStickerRepository implements StickerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const int _pageSize = 100;

  /// Supported sticker formats
  static const List<String> _supportedFormats = [
    '.webp',
    '.png',
    '.jpg',
    '.jpeg'
  ];

  bool _isSupported(String name) {
    final lower = name.toLowerCase();
    return _supportedFormats.any((ext) => lower.endsWith(ext));
  }

  @override
  Future<List<String>> getStickerUrls() async {
    try {
      final files = await _supabase.storage.from('assets').list(path: 'stickers');

      final imageFiles = files.where((f) => _isSupported(f.name)).toList();

      return imageFiles.map((file) {
        return _supabase.storage
            .from('assets')
            .getPublicUrl('stickers/${file.name}');
      }).toList();
    } catch (e) {
      throw Exception('Failed to load stickers: $e');
    }
  }

  @override
  Future<Map<String, List<String>>> getStickersByCategory() async {
    final folders = await _supabase.storage.from('assets').list(path: 'stickers');

    /// Detect folders (categories)
    final categoryNames = folders
        .where((f) => f.metadata == null || f.metadata!['eTag'] == null)
        .map((f) => f.name)
        .toList();

    final Map<String, List<String>> result = {};

    for (final category in categoryNames) {
      bool hasMore = true;
      final List<String> urls = [];

      while (hasMore) {
        final files = await _supabase.storage.from('assets').list(
          path: 'stickers/$category',
          searchOptions: const SearchOptions(limit: _pageSize),
        );

        final imageFiles = files.where((f) => _isSupported(f.name)).toList();

        for (final file in imageFiles) {
          final url = _supabase.storage
              .from('assets')
              .getPublicUrl('stickers/$category/${file.name}');
          urls.add(url);
        }

        if (files.length < _pageSize) {
          hasMore = false;
        } else {
        }
      }

      result[category] = urls;
    }

    return result;
  }

  @override
  Future<String> downloadSticker(String url) async {
    try {
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;

      final appDir = await getApplicationDocumentsDirectory();
      final stickerDir = Directory('${appDir.path}/stickers');

      if (!await stickerDir.exists()) {
        await stickerDir.create(recursive: true);
      }

      final localFile = File('${stickerDir.path}/$fileName');

      /// Return cached sticker if already downloaded
      if (await localFile.exists()) {
        return localFile.path;
      }

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      await localFile.writeAsBytes(response.bodyBytes);

      return localFile.path;
    } catch (e) {
      throw Exception('Sticker download failed: $e');
    }
  }
}