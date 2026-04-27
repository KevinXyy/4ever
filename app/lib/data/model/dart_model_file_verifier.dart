import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../application/ai/model/model_file_verifier.dart';

class DartModelFileVerifier implements ModelFileVerifier {
  const DartModelFileVerifier();

  @override
  Future<bool> exists(String path) {
    return File(path).exists();
  }

  @override
  Future<int> length(String path) {
    return File(path).length();
  }

  @override
  Future<bool> verifySha256({
    required String path,
    required String expectedSha256,
  }) async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString().toLowerCase() == expectedSha256.toLowerCase();
  }
}
