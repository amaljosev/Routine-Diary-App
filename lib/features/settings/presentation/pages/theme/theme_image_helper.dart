import 'dart:io';
import 'package:flutter/material.dart';

/// Utility for rendering theme header images that may be either:
/// - A bundled asset  (path starts with 'assets/')
/// - An absolute file-system path  (gallery-picked, saved to app docs dir)
///
/// Use [ThemeImageHelper.buildImage] everywhere a theme header is displayed —
/// in the diary home screen, custom theme preview, etc. — so the same logic
/// is applied consistently and you never accidentally call Image.asset() on
/// a file-system path (which throws "Asset not found").
class ThemeImageHelper {
  ThemeImageHelper._();

  /// Returns true when [path] refers to a bundled asset.
  static bool isAssetPath(String path) => path.startsWith('assets/');

  /// Builds the correct [Image] widget for [path] without the caller needing
  /// to know whether it is an asset or a file.
  static Widget buildImage(
    String path, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (isAssetPath(path)) {
      return Image.asset(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    } else {
      return Image.file(
        File(path),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }
  }

  /// Convenience method that wraps [buildImage] in a [SizedBox] with a fixed
  /// height — useful for header banners in the diary home screen.
  static Widget buildHeader(
    String path, {
    double height = 200,
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: buildImage(
        path,
        fit: fit,
        errorBuilder: errorBuilder,
      ),
    );
  }
}