class LlmModelConfig {
  const LlmModelConfig({
    required this.modelId,
    required this.localPath,
    required this.sha256,
    required this.sizeBytes,
    required this.minMemoryGb,
    required this.supportsText,
    required this.supportsImage,
    required this.supportsAudio,
    required this.supportsThinking,
    required this.maxContextTokens,
  });

  final String modelId;
  final String localPath;
  final String sha256;
  final int sizeBytes;
  final int minMemoryGb;
  final bool supportsText;
  final bool supportsImage;
  final bool supportsAudio;
  final bool supportsThinking;
  final int maxContextTokens;
}
