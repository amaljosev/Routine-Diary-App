import 'package:flutter/material.dart';

Color? parseDiaryColor(String? input) {
  if (input == null || input.isEmpty) return null;
  final String s = input.trim();

  // ── 8-char raw hex ─────────────────────────────────────────────────────────
  if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(s)) {
    return Color(int.parse(s, radix: 16));
  }

  final colorMatch =
      RegExp(r'^Color\(0x([0-9a-fA-F]{8})\)$').firstMatch(s);
  if (colorMatch != null) {
    return Color(int.parse(colorMatch.group(1)!, radix: 16));
  }

  // ── red: R, green: G, blue: B, alpha: A ───────────────────────────────────
  final componentMatch = RegExp(
    r'red:\s*([0-9.]+),\s*green:\s*([0-9.]+),\s*blue:\s*([0-9.]+),\s*alpha:\s*([0-9.]+)',
  ).firstMatch(s);
  if (componentMatch != null) {
    try {
      return Color.fromRGBO(
        (double.parse(componentMatch.group(1)!) * 255).round(),
        (double.parse(componentMatch.group(2)!) * 255).round(),
        (double.parse(componentMatch.group(3)!) * 255).round(),
        double.parse(componentMatch.group(4)!),
      );
    } catch (_) {}
  }

  // ── #RGB / 0xRGB / bare hex ────────────────────────────────────────────────
  String hex = s;
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.startsWith('0x')) hex = hex.substring(2);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length == 8) {
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {}
  }

  return null;
}