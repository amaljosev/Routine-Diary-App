import 'dart:io';
import 'package:flutter/material.dart';


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