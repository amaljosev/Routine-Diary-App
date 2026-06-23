// lib/features/backup/data/datasources/drive_remote_datasource.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;

import '../../../../core/error/exceptions.dart';
import '../models/backup_manifest_model.dart';
import 'google_auth_datasource.dart';

/// Drive appDataFolder operations.
class DriveRemoteDataSource {
  final GoogleAuthDataSource authDataSource;
  const DriveRemoteDataSource(this.authDataSource);

  static const String _appDataFolder = 'appDataFolder';

  /// Name prefix used for diary JSON manifests.
  /// Image files never have this prefix, so filtering by it reliably
  /// separates JSON backups from their companion image files.
  static const String _backupPrefix = 'diary_backup_';

  Future<drive.DriveApi> _api() async {
    final client = await authDataSource.authClient();
    return drive.DriveApi(client);
  }

  // ── Upload ────────────────────────────────────────────────────────

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

  Future<String> uploadImageFile({
    required String localPath,
    required String fileName,
  }) {
    return _run(() async {
      final api = await _api();
      final file = File(localPath);
      final bytes = await file.readAsBytes();

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: _mimeType(localPath),
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

  // ── List ──────────────────────────────────────────────────────────

  /// Returns only the diary JSON manifests (files whose name starts with
  /// [_backupPrefix]).  Image files uploaded alongside backups are excluded,
  /// so they never appear in the UI as 0-KB restore targets.
  Future<List<BackupManifestModel>> listBackups() {
    return _run(() async {
      final api = await _api();
      final result = await api.files.list(
        spaces: _appDataFolder,
        // Filter to only JSON manifests by name prefix.
        q: "name contains '$_backupPrefix'",
        orderBy: 'createdTime desc',
        $fields: 'files(id,name,size,createdTime,appProperties)',
        pageSize: 100,
      );
      final files = result.files ?? const [];
      return files.map(BackupManifestModel.fromDriveFile).toList();
    });
  }

  /// Lists EVERY file in appDataFolder (JSON manifests + images).
  /// Used by [BackupRepositoryImpl._deleteAllBackupsAndImages] to wipe Drive
  /// clean before uploading a fresh snapshot.
  Future<List<drive.File>> listAllFiles() {
    return _run(() async {
      final api = await _api();
      final result = await api.files.list(
        spaces: _appDataFolder,
        $fields: 'files(id)',
        pageSize: 1000,
      );
      return result.files ?? const [];
    });
  }

  // ── Download ──────────────────────────────────────────────────────

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

  // ── Delete ────────────────────────────────────────────────────────

  /// Deletes a single file by its Drive file ID.
  /// Works for both JSON manifests and image files.
  Future<void> deleteFile(String driveFileId) {
    return _run(() async {
      final api = await _api();
      await api.files.delete(driveFileId);
    });
  }

  // ── Error handling ────────────────────────────────────────────────

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
              'Your organisation has blocked Drive access.');
        default:
          return ServerException('Drive denied the request: $reason');
      }
    }
    if (status != null && status >= 500) {
      return ServerException('Drive server error ($status).');
    }
    return ServerException('Drive error ($status): ${e.message}');
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