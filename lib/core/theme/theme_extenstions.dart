import 'package:flutter/material.dart';

class BackgroundImageTheme extends ThemeExtension<BackgroundImageTheme> {
  final String? imagePath;

  const BackgroundImageTheme({this.imagePath});

  @override
  ThemeExtension<BackgroundImageTheme> copyWith({String? imagePath}) {
    return BackgroundImageTheme(imagePath: imagePath ?? this.imagePath);
  }

  @override
  ThemeExtension<BackgroundImageTheme> lerp(
    covariant ThemeExtension<BackgroundImageTheme>? other,
    double t,
  ) {
    if (other is! BackgroundImageTheme) return this;
    return BackgroundImageTheme(
      imagePath: imagePath, 
    );
  }
}