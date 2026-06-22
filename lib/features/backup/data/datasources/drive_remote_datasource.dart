// lib/features/backup/data/datasources/drive_remote_datasource.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';


import 'package:googleapis/drive/v3.dart' as drive;

import '../../../../core/error/exceptions.dart';
import '../models/backup_manifest_model.dart';
import 'google_auth_datasource.dart';

/// Drive appDataFolder operations (no DI; takes auth datasource by ctor).
class DriveRemoteDataSource {
  final GoogleAuthDataSource authDataSource;
  const DriveRemoteDataSource(this.authDataSource);

  static const String _appDataFolder = 'appDataFolder';

  Future<drive.DriveApi> _api() async {
    final client = await authDataSource.authClient();
    return drive.DriveApi(client);
  }

  Future<BackupManifestModel> uploadBackup({
    required String fileName,
    required String jsonContent,
    required Map<String, String> appProperties,
  }) {
    return _run(() async {
      final api = await _api();
      final bytes = utf8.encode(jsonContent);
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );
      final fileMeta = drive.File()
        ..name = fileName
        ..parents = [_appDataFolder]
        ..appProperties = appProperties;

      final created = await api.files.create(
        fileMeta,
        uploadMedia: media,
        $fields: 'id,name,size,createdTime,appProperties',
      );
      return BackupManifestModel.fromDriveFile(created);
    });
  }

  Future<List<BackupManifestModel>> listBackups() {
    return _run(() async {
      final api = await _api();
      final result = await api.files.list(
        spaces: _appDataFolder,
        orderBy: 'createdTime desc',
        $fields: 'files(id,name,size,createdTime,appProperties)',
        pageSize: 100,
      );
      final files = result.files ?? const [];
      return files.map(BackupManifestModel.fromDriveFile).toList();
    });
  }

  Future<String> downloadBackup(String driveFileId) {
    return _run(() async {
      final api = await _api();
      final media = await api.files.get(
        driveFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final chunks = <int>[];
      await for (final chunk in media.stream) {
        chunks.addAll(chunk);
      }
      return utf8.decode(chunks);
    });
  }

  Future<void> deleteBackup(String driveFileId) {
    return _run(() async {
      final api = await _api();
      await api.files.delete(driveFileId);
    });
  }

  /// Central error translation for all Drive calls.
  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on drive.DetailedApiRequestError catch (e) {
      throw _mapDriveError(e);
    } on AuthExpiredException {
      rethrow;
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const NetworkException('No internet connection.');
    } on TimeoutException {
      throw const NetworkTimeoutException('Drive request timed out.');
    } catch (e) {
      throw ServerException('Unexpected Drive error: $e');
    }
  }

  Exception _mapDriveError(drive.DetailedApiRequestError e) {
    final status = e.status;
    final reason = (e.errors.isNotEmpty ? e.errors.first.reason : null) ?? '';
    if (status == 401) {
      return const AuthExpiredException('Drive session expired.');
    }
    if (status == 403) {
      switch (reason) {
        case 'storageQuotaExceeded':
          return const StorageFullException(
              'Google Drive storage is full. Free up space and try again.');
        case 'rateLimitExceeded':
        case 'userRateLimitExceeded':
          return const RateLimitException('Too many requests. Try again shortly.');
        case 'domainPolicy':
          return const DomainPolicyException(
              'Your organization has blocked Drive access.');
        default:
          return ServerException('Drive denied the request: $reason');
      }
    }
    if (status != null && status >= 500) {
      return ServerException('Drive server error ($status).');
    }
    return ServerException('Drive error ($status): ${e.message}');
  }
  /// Uploads a local image file to appDataFolder.
/// Returns the Drive file ID of the uploaded file.
Future<String> uploadImageFile({
  required String localPath,
  required String fileName,
}) {
  return _run(() async {
    final api = await _api();
    final file = File(localPath);
    final bytes = await file.readAsBytes();
    final mimeType = _mimeType(localPath);

    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: mimeType,
    );
    final fileMeta = drive.File()
      ..name = fileName
      ..parents = [_appDataFolder];

    final created = await api.files.create(
      fileMeta,
      uploadMedia: media,
      $fields: 'id',
    );
    return created.id!;
  });
}

/// Downloads a Drive file to [destinationPath].
Future<void> downloadImageFile({
  required String driveFileId,
  required String destinationPath,
}) {
  return _run(() async {
    final api = await _api();
    final media = await api.files.get(
      driveFileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final chunks = <int>[];
    await for (final chunk in media.stream) {
      chunks.addAll(chunk);
    }

    final dest = File(destinationPath);
    await dest.parent.create(recursive: true);
    await dest.writeAsBytes(chunks);
  });
}

String _mimeType(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    default:
      return 'application/octet-stream';
  }
}
}