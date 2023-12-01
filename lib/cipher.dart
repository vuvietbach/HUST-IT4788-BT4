import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import "package:pointycastle/export.dart";

Uint8List aesCbcEncrypt(
    Uint8List key, Uint8List iv, Uint8List paddedPlaintext) {
  assert([128, 192, 256].contains(key.length * 8));
  assert(128 == iv.length * 8);
  // assert(128 == paddedPlaintext.length * 8);

  // Create a CBC block cipher with AES, and initialize with key and IV

  final cbc = CBCBlockCipher(AESEngine())
    ..init(true, ParametersWithIV(KeyParameter(key), iv)); // true=encrypt

  // Encrypt the plaintext block-by-block

  final cipherText = Uint8List(paddedPlaintext.length); // allocate space

  var offset = 0;
  while (offset < paddedPlaintext.length) {
    offset += cbc.processBlock(paddedPlaintext, offset, cipherText, offset);
  }
  assert(offset == paddedPlaintext.length);

  return cipherText;
}

Uint8List aesCbcDecrypt(Uint8List key, Uint8List iv, Uint8List cipherText) {
  assert([128, 192, 256].contains(key.length * 8));
  assert(128 == iv.length * 8);
  // assert(128 == cipherText.length * 8);

  // Create a CBC block cipher with AES, and initialize with key and IV

  final cbc = CBCBlockCipher(AESEngine())
    ..init(false, ParametersWithIV(KeyParameter(key), iv)); // false=decrypt

  // Decrypt the cipherText block-by-block

  final paddedPlainText = Uint8List(cipherText.length); // allocate space

  var offset = 0;
  while (offset < cipherText.length) {
    offset += cbc.processBlock(cipherText, offset, paddedPlainText, offset);
  }
  assert(offset == cipherText.length);

  return paddedPlainText;
}
Uint8List getKey() {
  final key = Uint8List.fromList(List.generate(32, (index) => Random().nextInt(256)));
  return key;
}
Uint8List getInitVector() {
  final iv = Uint8List.fromList(List.generate(16, (index) => Random().nextInt(256)));
  return iv;
}

void main() {
  // Generate a random 256-bit key
  final key = Uint8List.fromList(List.generate(32, (index) => Random().nextInt(256)));

  // Generate a random 128-bit IV
  final iv = Uint8List.fromList(List.generate(16, (index) => Random().nextInt(256)));

  // Convert the plaintext to bytes
  final plaintext = utf8.encode("b%b%UE1A.230829.019%com.example.exp1%1.0.0%1701410502");

  // Add PKCS7 padding to the plaintext
  final paddedPlaintext = padPlaintext(plaintext);

  // Encrypt the plaintext
  final cipherText = aesCbcEncrypt(key, iv, paddedPlaintext);
  print('Encrypted: ${base64.encode(cipherText)}');

  // Decrypt the ciphertext
  final decryptedPlaintext = aesCbcDecrypt(key, iv, cipherText);
  print('Decrypted: ${utf8.decode(removePadding(decryptedPlaintext))}');
}

Uint8List padPlaintext(Uint8List plaintext) {
  const blockSize = 16;
  final padding = blockSize - (plaintext.length % blockSize);
  final paddedPlaintext = Uint8List(plaintext.length + padding);
  paddedPlaintext
    ..setAll(0, plaintext)
    ..fillRange(plaintext.length, paddedPlaintext.length, padding);
  return paddedPlaintext;
}

Uint8List removePadding(Uint8List paddedPlaintext) {
  final padding = paddedPlaintext.last;
  return Uint8List.sublistView(paddedPlaintext, 0, paddedPlaintext.length - padding);
}
