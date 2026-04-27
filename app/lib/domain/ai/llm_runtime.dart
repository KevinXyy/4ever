import 'llm_generation_config.dart';
import 'llm_model_config.dart';
import 'llm_response.dart';
import 'llm_runtime_status.dart';
import 'llm_token_event.dart';

abstract interface class LlmRuntime {
  Future<void> initialize(LlmModelConfig config);

  Stream<LlmTokenEvent> generateStream({
    required String prompt,
    List<Object> attachments = const <Object>[],
    LlmGenerationConfig config = const LlmGenerationConfig(),
  });

  Future<LlmResponse> generateOnce({
    required String prompt,
    List<Object> attachments = const <Object>[],
    LlmGenerationConfig config = const LlmGenerationConfig(),
  });

  Future<LlmRuntimeStatus> getStatus();

  Future<void> cancel();

  Future<void> unload();
}
