import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:routine/features/diary/domain/repository/background_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBackgroundRepository implements BackgroundRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<String>> getBackgroundUrls() async {
    try {
      final files = await _supabase.storage.from('assets').list(path: 'bg_presets');
      final imageFiles = files.where((f) => f.metadata?['mimetype'] != null).toList();
      return imageFiles.map((file) {
        return _supabase.storage.from('assets').getPublicUrl('bg_presets/${file.name}');
      }).toList();
    } catch (e) {
      throw Exception('Failed to load background images: $e');
    }
  }

  @override
  Future<String> downloadBackground(String url) async {
    try {
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last; // e.g., "sunset.jpg"

      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final bgDir = Directory('${appDir.path}/backgrounds');
      if (!await bgDir.exists()) {
        await bgDir.create(recursive: true);
      }

      final localFile = File('${bgDir.path}/$fileName');

      // If file already exists, return path immediately
      if (await localFile.exists()) {
        return localFile.path;
      }

      // Download file using http
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      // Write to file
      await localFile.writeAsBytes(response.bodyBytes);
      return localFile.path;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }
}