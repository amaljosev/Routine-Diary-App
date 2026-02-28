import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BgPresetScreen extends StatefulWidget {
  const BgPresetScreen({super.key});

  @override
  State<BgPresetScreen> createState() => _BgPresetScreenState();
}

class _BgPresetScreenState extends State<BgPresetScreen> {
  final supabase = Supabase.instance.client;

  Future<List<String>> _loadImages() async {
    try {
      log("🔵 Loading images from root of 'assets' bucket...");

      final files = await supabase.storage
    .from('assets')
    .list(path: 'bg_presets');

      log("📦 Files count: ${files.length}");
      log("📦 Raw files: $files");

      if (files.isEmpty) {
        log("🟡 Bucket is empty");
        return [];
      }

      final urls = <String>[];

      for (final file in files) {
        // Ignore folders (if any)
        if (file.metadata?['mimetype'] == null) continue;

        final publicUrl = supabase.storage
            .from('assets')
            .getPublicUrl("bg_presets/${file.name}");

        log("🔗 Generated URL: $publicUrl");

        urls.add(publicUrl);
      }

      log("✅ URLs generated successfully");
      return urls;
    } catch (e, stack) {
      log("🔴 ERROR loading images", error: e, stackTrace: stack);
      rethrow;
    }
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FutureBuilder<List<String>>(
          future: _loadImages(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 350,
                child: Center(
                  child: Text(
                    "Error loading images\n${snapshot.error}",
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 250,
                child: Center(child: Text("No images found")),
              );
            }

            final images = snapshot.data!;

            return SizedBox(
              height: 500,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.5,
                ),
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    height: 200,
                    width: 50,
                    imageUrl: images[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) {
                      log("❌ Image load failed: $error");
                      return const Icon(Icons.error);
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _showBottomSheet,
          child: const Text("Open Background Presets"),
        ),
      ),
    );
  }
}
