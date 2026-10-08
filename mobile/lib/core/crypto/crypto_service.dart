import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

class EncryptedPayload {
  EncryptedPayload({
    required this.ciphertext,
    required this.nonceB64,
    required this.wrappedKeyB64,
    required this.wrapNonceB64,
    required this.checksumSha256,
  });

  final Uint8List ciphertext;
  final String nonceB64;
  final String wrappedKeyB64;
  final String wrapNonceB64;
  final String checksumSha256;
}

class CryptoService {
  static const int _pbkdf2Iterations = 120000;
  static const int _keyLength = 32;

  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pbkdf2Iterations,
    bits: _keyLength * 8,
  );

  final AesGcm _aes = AesGcm.with256bits();

  SecretKey? _masterKey;

  bool get hasMasterKey => _masterKey != null;

  Future<void> deriveAndSetMasterKey({
    required String password,
    required Uint8List salt,
  }) async {
    _masterKey = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  void clearMasterKey() {
    _masterKey = null;
  }

  Future<EncryptedPayload> encryptFile(Uint8List plaintext) async {
    final master = _requireMaster();
    final fileKeyBytes = _randomBytes(32);
    final fileKey = SecretKey(fileKeyBytes);

    final encrypted = await _aes.encrypt(plaintext, secretKey: fileKey);
    final ciphertext = Uint8List.fromList([
      ...encrypted.cipherText,
      ...encrypted.mac.bytes,
    ]);

    final wrapped = await _aes.encrypt(fileKeyBytes, secretKey: master);

    final checksum = crypto.sha256.convert(ciphertext).toString();

    return EncryptedPayload(
      ciphertext: ciphertext,
      nonceB64: base64Encode(encrypted.nonce),
      wrappedKeyB64: base64Encode([
        ...wrapped.cipherText,
        ...wrapped.mac.bytes,
      ]),
      wrapNonceB64: base64Encode(wrapped.nonce),
      checksumSha256: checksum,
    );
  }

  Future<Uint8List> decryptFile({
    required Uint8List ciphertextWithMac,
    required String nonceB64,
    required String wrappedKeyB64,
    required String wrapNonceB64,
    required String expectedChecksum,
  }) async {
    final master = _requireMaster();
    final actual = crypto.sha256.convert(ciphertextWithMac).toString();
    if (actual.toLowerCase() != expectedChecksum.toLowerCase()) {
      throw StateError('Échec de vérification d’intégrité (checksum).');
    }

    final wrapBytes = base64Decode(wrappedKeyB64);
    if (wrapBytes.length < 17) {
      throw StateError('Clé wrappée invalide.');
    }
    final wrapMac = Mac(wrapBytes.sublist(wrapBytes.length - 16));
    final wrapCipher = wrapBytes.sublist(0, wrapBytes.length - 16);
    final unwrapped = await _aes.decrypt(
      SecretBox(wrapCipher, nonce: base64Decode(wrapNonceB64), mac: wrapMac),
      secretKey: master,
    );

    if (ciphertextWithMac.length < 17) {
      throw StateError('Ciphertext invalide.');
    }
    final mac = Mac(ciphertextWithMac.sublist(ciphertextWithMac.length - 16));
    final cipher = ciphertextWithMac.sublist(0, ciphertextWithMac.length - 16);
    final plain = await _aes.decrypt(
      SecretBox(cipher, nonce: base64Decode(nonceB64), mac: mac),
      secretKey: SecretKey(unwrapped),
    );
    return Uint8List.fromList(plain);
  }

  SecretKey _requireMaster() {
    final key = _masterKey;
    if (key == null) {
      throw StateError('Clé maître absente. Reconnectez-vous.');
    }
    return key;
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
