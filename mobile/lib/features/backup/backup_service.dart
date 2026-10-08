import 'dart:typed_data';

import '../../core/api/api_client.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/io/save_file.dart';
import '../../core/models/models.dart';
import '../../core/platform_info.dart';
import '../../core/storage/session_store.dart';

class BackupService {
  BackupService({
    required this.api,
    required this.crypto,
    required this.store,
  });

  final ApiClient api;
  final CryptoService crypto;
  final SessionStore store;

  Future<FileModel> backupBytes({
    required Uint8List bytes,
    required String logicalName,
    required String mime,
    int? existingFileId,
    void Function(double progress)? onProgress,
  }) async {
    final encrypted = await crypto.encryptFile(bytes);
    final deviceUid = await store.getOrCreateDeviceUid();

    return api.uploadEncrypted(
      encryptedBytes: encrypted.ciphertext,
      logicalName: logicalName,
      mime: mime,
      checksumSha256: encrypted.checksumSha256,
      nonceB64: encrypted.nonceB64,
      wrappedKeyB64: encrypted.wrappedKeyB64,
      wrapNonceB64: encrypted.wrapNonceB64,
      deviceUid: deviceUid,
      deviceName: deviceDisplayName(),
      fileId: existingFileId,
      onProgress: (sent, total) {
        if (total > 0 && onProgress != null) {
          onProgress(sent / total);
        }
      },
    );
  }

  Future<Uint8List> decryptFileBytes({
    required int fileId,
    int? version,
  }) async {
    final download = await api.download(fileId, version: version);
    return crypto.decryptFile(
      ciphertextWithMac: download.bytes,
      nonceB64: download.nonceB64,
      wrappedKeyB64: download.wrappedKeyB64,
      wrapNonceB64: download.wrapNonceB64,
      expectedChecksum: download.checksumSha256,
    );
  }

  Future<String> restoreFile({
    required int fileId,
    int? version,
  }) async {
    final download = await api.download(fileId, version: version);
    final plain = await crypto.decryptFile(
      ciphertextWithMac: download.bytes,
      nonceB64: download.nonceB64,
      wrappedKeyB64: download.wrappedKeyB64,
      wrapNonceB64: download.wrapNonceB64,
      expectedChecksum: download.checksumSha256,
    );

    return saveRestoredFile(
      fileName: download.logicalName,
      bytes: plain,
      mime: download.mime,
    );
  }
}
