import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;

class ZeytinTokener {
  final Uint8List _key;
  final Random _random = Random.secure();

  ZeytinTokener(String passphrase) : _key = _deriveKey(passphrase);

  static Uint8List _deriveKey(String passphrase) {
    return Uint8List.fromList(
      sha256.convert(utf8.encode(passphrase)).bytes,
    );
  }

  pc.PaddedBlockCipher _createCipher(
    bool forEncryption,
    Uint8List iv,
  ) {
    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7');

    cipher.init(
      forEncryption,
      pc.PaddedBlockCipherParameters<
          pc.ParametersWithIV<pc.KeyParameter>, Null>(
        pc.ParametersWithIV<pc.KeyParameter>(
          pc.KeyParameter(_key),
          iv,
        ),
        null,
      ),
    );

    return cipher;
  }

  String encryptString(String text) {
    final iv = Uint8List.fromList(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );

    final encrypted = _createCipher(true, iv).process(
      Uint8List.fromList(utf8.encode(text)),
    );

    return '${base64Encode(iv)}:${base64Encode(encrypted)}';
  }

  String decryptString(String encryptedData) {
    return _decrypt(encryptedData, 'Invalid format');
  }

  String _decrypt(String encryptedData, String formatError) {
    final parts = encryptedData.split(':');

    if (parts.length != 2) {
      throw FormatException(formatError);
    }

    final iv = base64Decode(parts[0]);
    final ciphertext = base64Decode(parts[1]);

    if (iv.length != 16) {
      throw FormatException('Invalid IV length');
    }

    if (ciphertext.isEmpty || ciphertext.length % 16 != 0) {
      throw FormatException('Invalid ciphertext length');
    }

    final decrypted = _createCipher(false, iv).process(ciphertext);
    return utf8.decode(decrypted, allowMalformed: true);
  }

  String encryptMap(Map<String, dynamic> data) {
    return encryptString(jsonEncode(data));
  }

  Map<String, dynamic> decryptMap(String encryptedData) {
    final decrypted = _decrypt(
      encryptedData,
      'Invalid encrypted data format',
    );

    return jsonDecode(decrypted) as Map<String, dynamic>;
  }
}