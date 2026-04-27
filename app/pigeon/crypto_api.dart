import 'dart:typed_data';

import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class CryptoHostApi {
  @async
  String getOrCreateDatabaseKeyId();

  @async
  Uint8List encrypt(Uint8List plaintext, String keyId);

  @async
  Uint8List decrypt(Uint8List ciphertext, String keyId);
}
