import 'dart:convert';
import 'dart:typed_data';

import 'package:arsave_mobile/core/crypto/crypto_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encrypt then decrypt roundtrip', () async {
    final crypto = CryptoService();
    final salt = Uint8List.fromList(List<int>.generate(32, (i) => i));
    await crypto.deriveAndSetMasterKey(password: 'SecretPass1', salt: salt);

    final plain = Uint8List.fromList(utf8.encode('hello ARSAVE'));
    final enc = await crypto.encryptFile(plain);
    expect(enc.ciphertext, isNotEmpty);
    expect(enc.checksumSha256.length, 64);

    final out = await crypto.decryptFile(
      ciphertextWithMac: enc.ciphertext,
      nonceB64: enc.nonceB64,
      wrappedKeyB64: enc.wrappedKeyB64,
      wrapNonceB64: enc.wrapNonceB64,
      expectedChecksum: enc.checksumSha256,
    );
    expect(utf8.decode(out), 'hello ARSAVE');
  });
}
