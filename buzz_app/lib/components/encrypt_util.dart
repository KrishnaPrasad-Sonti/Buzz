import 'package:encrypt/encrypt.dart' as enc;


class EncryptionUtil {
  static final _key = enc.Key.fromUtf8('buzzbuzzbuzzbuzz'); // 16-char key
  static final _iv = enc.IV.fromLength(16);
  static final _encrypter = enc.Encrypter(enc.AES(_key));

  static String encrypt(String plainText) {
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }

  static String decrypt(String encryptedText) {
    return _encrypter.decrypt64(encryptedText, iv: _iv);
  }
}
