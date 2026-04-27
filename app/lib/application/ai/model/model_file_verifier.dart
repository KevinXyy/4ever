abstract interface class ModelFileVerifier {
  Future<bool> exists(String path);

  Future<int> length(String path);

  Future<bool> verifySha256({
    required String path,
    required String expectedSha256,
  });
}
