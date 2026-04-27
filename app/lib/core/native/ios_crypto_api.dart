import 'package:flutter/services.dart';

import 'native_channel_names.dart';

class IosCryptoApi {
  IosCryptoApi({
    MethodChannel? methodChannel,
  }) : _methodChannel = methodChannel ??
            const MethodChannel(NativeChannelNames.crypto);

  final MethodChannel _methodChannel;

  Future<String> getOrCreateDatabaseKeyId() async {
    final keyId = await _methodChannel.invokeMethod<String>(
      'getOrCreateDatabaseKeyId',
    );
    return keyId ?? 'database-key';
  }

  Future<Uint8List> encrypt(Uint8List plaintext, String keyId) async {
    final result = await _methodChannel.invokeMethod<Uint8List>(
      'encrypt',
      <String, Object?>{
        'plaintext': plaintext,
        'key_id': keyId,
      },
    );
    return result ?? Uint8List(0);
  }

  Future<Uint8List> decrypt(Uint8List ciphertext, String keyId) async {
    final result = await _methodChannel.invokeMethod<Uint8List>(
      'decrypt',
      <String, Object?>{
        'ciphertext': ciphertext,
        'key_id': keyId,
      },
    );
    return result ?? Uint8List(0);
  }
}
