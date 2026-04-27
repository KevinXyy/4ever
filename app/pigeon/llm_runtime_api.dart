import 'package:pigeon/pigeon.dart';

class NativeLlmModelConfig {
  NativeLlmModelConfig({
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

  String modelId;
  String localPath;
  String sha256;
  int sizeBytes;
  int minMemoryGb;
  bool supportsText;
  bool supportsImage;
  bool supportsAudio;
  bool supportsThinking;
  int maxContextTokens;
}

class NativeGenerationConfig {
  NativeGenerationConfig({
    required this.temperature,
    required this.topK,
    required this.topP,
    required this.maxTokens,
    required this.enableThinking,
  });

  double temperature;
  int topK;
  double topP;
  int maxTokens;
  bool enableThinking;
}

class NativeLlmStatus {
  NativeLlmStatus({
    required this.state,
    this.errorCode,
    this.errorMessage,
    this.usedMemoryMb,
    this.loadedModelId,
  });

  String state;
  String? errorCode;
  String? errorMessage;
  int? usedMemoryMb;
  String? loadedModelId;
}

@HostApi()
abstract class LlmRuntimeHostApi {
  @async
  void initialize(NativeLlmModelConfig config);

  @async
  String generateOnce(String prompt, NativeGenerationConfig config);

  @async
  void cancel();

  @async
  void unload();

  @async
  NativeLlmStatus getStatus();
}
