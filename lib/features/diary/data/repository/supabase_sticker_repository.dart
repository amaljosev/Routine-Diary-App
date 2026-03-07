import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:routine/features/diary/domain/repository/sticker_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStickerRepository implements StickerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<String>> getStickerUrls() async {
    try {
      final files = await _supabase.storage.from('assets').list(path: 'stickers');
      final svgFiles = files.where((f) => f.name.endsWith('.svg')).toList();
      return svgFiles.map((file) {
        return _supabase.storage.from('assets').getPublicUrl('stickers/${file.name}');
      }).toList();
    } catch (e) {
      throw Exception('Failed to load stickers: $e');
    }
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