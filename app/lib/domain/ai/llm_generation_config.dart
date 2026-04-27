class LlmGenerationConfig {
  const LlmGenerationConfig({
    this.temperature = 0.7,
    this.topK = 40,
    this.topP = 0.95,
    this.maxTokens = 512,
    this.enableThinking = false,
  });

  final double temperature;
  final int topK;
  final double topP;
  final int maxTokens;
  final bool enableThinking;
}
