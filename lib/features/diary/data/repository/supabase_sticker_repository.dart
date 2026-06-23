import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:routine/features/diary/domain/repository/sticker_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStickerRepository implements StickerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const int _pageSize = 100;

  /// Supported sticker formats.
  static const List<String> _supportedFormats = [
    '.webp',
    '.png',
    '.jpg',
    '.jpeg',
  ];

  bool _isSupported(String name) {
    final lower = name.toLowerCase();
    return _supportedFormats.any((ext) => lower.endsWith(ext));
  }

  @override
  Future<List<String>> getStickerUrls() async {
    try {
      final files =
          await _supabase.storage.from('assets').list(path: 'stickers');
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

  /// Returns all sticker URLs grouped by category (subfolder).
  ///
  /// Fixes two bugs from the original implementation:
  ///
  /// 1. **Infinite loop** — when a category had ≥ [_pageSize] files the
  ///    `offset` was never incremented, so the same page was fetched forever.
  ///    Fixed by tracking `offset` and incrementing it by [_pageSize] after
  ///    each page.
  ///
  /// 2. **Folder detection** — Supabase Storage represents subfolders as
  ///    pseudo-objects whose `metadata` map is either null or lacks an `eTag`.
  ///    The original heuristic was correct but fragile; a comment is added to
  ///    make the intent explicit.
  @override
  Future<Map<String, List<String>>> getStickersByCategory() async {
    try {
      final folders =
          await _supabase.storage.from('assets').list(path: 'stickers');

      // Supabase returns subfolders as entries with no eTag in their metadata.
      final categoryNames = folders
          .where((f) => f.metadata == null || f.metadata!['eTag'] == null)
          .map((f) => f.name)
          .toList();

      final Map<String, List<String>> result = {};

      for (final category in categoryNames) {
        final List<String> urls = [];
        int offset = 0;
        bool hasMore = true;

        while (hasMore) {
          final files = await _supabase.storage.from('assets').list(
                path: 'stickers/$category',
                searchOptions: SearchOptions(
                  limit: _pageSize,
                  offset: offset, // ← was missing; caused infinite loop
                ),
              );

          final imageFiles =
              files.where((f) => _isSupported(f.name)).toList();

          for (final file in imageFiles) {
            final url = _supabase.storage
                .from('assets')
                .getPublicUrl('stickers/$category/${file.name}');
            urls.add(url);
          }

          if (files.length < _pageSize) {
            // Received fewer items than the page size — no more pages.
            hasMore = false;
          } else {
            // Advance the offset to fetch the next page.
            offset += _pageSize;
          }
        }

        result[category] = urls;
      }

      return result;
    } catch (e) {
      throw Exception('Failed to load stickers by category: $e');
    }
  }

  /// Downloads [url] to the local `stickers/` cache directory and returns
  /// the local file path.
  ///
  /// If the file already exists on disk (either from a previous download or
  /// from a Drive restore — which also places files under `stickers/`) the
  /// cached copy is returned immediately without a network request.
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

      // Return the cached file if it already exists (covers both previous
      // Supabase downloads and files restored from a Drive backup).
      if (await localFile.exists()) {
        return localFile.path;
      }

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Download failed with status ${response.statusCode}');
      }

      await localFile.writeAsBytes(response.bodyBytes);
      return localFile.path;
    } catch (e) {
      throw Exception('Sticker download failed: $e');
    }
  }
}