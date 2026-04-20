import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

import 'package:routine/features/diary/data/models/diary_entry_model.dart';

class DiaryExportService {
  static Future<String> exportToPdf(List<DiaryEntryModel> entries) async {
    await _ensurePermission();

    final pdf = pw.Document(
      title: 'Routine Diary Export',
      author: 'Routine Diary App',
    );

    final logoBytes = await rootBundle.load('assets/icons/routine_icon.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Sort newest first before building pages.
    final sorted = [...entries]..sort((a, b) {
        final da = DateTime.tryParse(a.date) ?? DateTime(0);
        final db = DateTime.tryParse(b.date) ?? DateTime(0);
        return db.compareTo(da);
      });

    final timelineText = _buildTimelineText(sorted);

    _addCoverPage(pdf, sorted.length, logoImage, timelineText);
    for (final entry in sorted) {
      _addEntryPage(pdf, entry);
    }

    final bytes = await pdf.save();
    final fileName =
        'Routine_Diary_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final savePath = await _resolveSavePath(fileName);

    final file = File(savePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);

    return savePath;
  }

  static String _buildTimelineText(List<DiaryEntryModel> entries) {
    final dates = entries
        .map((e) => DateTime.tryParse(e.date))
        .whereType<DateTime>()
        .toList();

    if (dates.isEmpty) return '';

    dates.sort();
    final start = dates.first;
    final end = dates.last;

    final startText = DateFormat('MMMM yyyy').format(start);
    final endText = DateFormat('MMMM yyyy').format(end);

    if (start.year == end.year && start.month == end.month) {
      return startText;
    }

    return '$startText — $endText';
  }

  static void _addCoverPage(
    pw.Document pdf,
    int entryCount,
    pw.ImageProvider logoImage,
    String timelineText,
  ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 60, vertical: 48),
        build: (_) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 88,
                height: 88,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColor.fromHex('#EEF0FF'),
                ),
                child: pw.Center(
                  child: pw.ClipOval(
                    child: pw.Image(
                      logoImage,
                      width: 60,
                      height: 60,
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 28),
              pw.Text(
                'Routine',
                style: pw.TextStyle(
                  fontSize: 38,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Capture your journey',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey500,
                ),
              ),
              if (timelineText.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  timelineText,
                  style: pw.TextStyle(
                    fontSize: 13,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
              pw.SizedBox(height: 36),
              pw.Container(width: 180, height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 36),
              pw.Text(
                '$entryCount ${entryCount == 1 ? 'entry' : 'entries'}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Exported on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _addEntryPage(pw.Document pdf, DiaryEntryModel entry) {
    final date = DateTime.tryParse(entry.date) ?? DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM dd yyyy').format(date);
    final content = (entry.content.isNotEmpty == true)
        ? entry.content
        : (entry.preview.isNotEmpty ? entry.preview : '');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 48),
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (_) => [
          pw.Text(
            formattedDate,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey500,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 18),
          if (entry.title.isNotEmpty) ...[
            pw.Text(
              entry.title,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
            pw.SizedBox(height: 16),
          ],
          pw.Text(
            content,
            style: pw.TextStyle(
              fontSize: 13,
              color: PdfColors.grey800,
              lineSpacing: 6,
            ),
          ),
          pw.SizedBox(height: 24),
        ],
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${ctx.pageNumber}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400),
          ),
        ),
      ),
    );
  }

  static Future<String> _resolveSavePath(String fileName) async {
    if (Platform.isAndroid) {
      const downloadsPath = '/storage/emulated/0/Download';
      if (await Directory(downloadsPath).exists()) {
        return '$downloadsPath/$fileName';
      }
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) return '${extDir.path}/$fileName';
    }
    final docDir = await getApplicationDocumentsDirectory();
    return '${docDir.path}/$fileName';
  }

  static Future<void> _ensurePermission() async {
    if (!Platform.isAndroid) return;

    final sdkInt = await _androidSdkInt();
    if (sdkInt >= 29) return;

    final status = await Permission.storage.status;
    if (status.isGranted || status.isLimited) return;

    if (status.isPermanentlyDenied) {
      throw Exception(
        'Storage permission is permanently denied. '
        'Please enable it in Settings → Apps → Routine → Permissions.',
      );
    }

    final result = await Permission.storage.request();
    if (!result.isGranted) {
      throw Exception(
        'Storage permission denied. '
        'Please allow storage access to save the PDF.',
      );
    }
  }

  static Future<int> _androidSdkInt() async {
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 29;
    } catch (_) {
      return 29;
    }
  }
}