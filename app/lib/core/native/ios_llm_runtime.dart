import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/ai/llm_generation_config.dart';
import '../../domain/ai/llm_model_config.dart';
import '../../domain/ai/llm_response.dart';
import '../../domain/ai/llm_runtime.dart';
import '../../domain/ai/llm_runtime_status.dart';
import '../../domain/ai/llm_token_event.dart';
import 'native_channel_names.dart';

class IosLlmRuntime implements LlmRuntime {
  IosLlmRuntime({MethodChannel? methodChannel, EventChannel? tokenChannel})
    : _methodChannel =
          methodChannel ?? const MethodChannel(NativeChannelNames.llmRuntime),
      _tokenChannel =
          tokenChannel ?? const EventChannel(NativeChannelNames.llmTokenStream);

  final MethodChannel _methodChannel;
  final EventChannel _tokenChannel;

  @override
  Future<void> initialize(LlmModelConfig config) async {
    await _methodChannel.invokeMethod<void>('initialize', config.toNativeMap());
  }

  @override
  Stream<LlmTokenEvent> generateStream({
    required String prompt,
    List<Object> attachments = const <Object>[],
    LlmGenerationConfig config = const LlmGenerationConfig(),
  }) async* {
    await _methodChannel.invokeMethod<void>('startStream', <String, Object?>{
      'prompt': prompt,
      'config': config.toNativeMap(),
    });

    yield* _tokenChannel.receiveBroadcastStream().map((Object? event) {
      final data = Map<String, Object?>.from(event! as Map<Object?, Object?>);
      return LlmTokenEvent(
        requestId: data['request_id']! as String,
        type: data['type']! as String,
        text: data['text'] as String?,
        errorCode: data['error_code'] as String?,
      );
    });
  }

  @override
  Future<LlmResponse> generateOnce({
    required String prompt,
    List<Object> attachments = const <Object>[],
    LlmGenerationConfig config = const LlmGenerationConfig(),
  }) async {
    final result = await _methodChannel.invokeMapMethod<String, Object?>(
      'generateOnce',
      <String, Object?>{'prompt': prompt, 'config': config.toNativeMap()},
    );

    return LlmResponse(
      text: result?['text'] as String? ?? '',
      modelId: result?['model_id'] as String? ?? 'unloaded',
    );
  }

  @override
  Future<LlmRuntimeStatus> getStatus() async {
    final result = await _methodChannel.invokeMapMethod<String, Object?>(
      'getStatus',
    );

    return LlmRuntimeStatus(
      state: result?['state'] as String? ?? 'unloaded',
      errorCode: result?['error_code'] as String?,
      errorMessage: result?['error_message'] as String?,
      usedMemoryMb: result?['used_memory_mb'] as int?,
      loadedModelId: result?['loaded_model_id'] as String?,
    );
  }

  @override
  Future<void> cancel() async {
    await _methodChannel.invokeMethod<void>('cancel');
  }

  @override
  Future<void> unload() async {
    await _methodChannel.invokeMethod<void>('unload');
  }
}

extension on LlmModelConfig {
  Map<String, Object?> toNativeMap() {
    return <String, Object?>{
      'model_id': modelId,
      'local_path': localPath,
      'sha256': sha256,
      'size_bytes': sizeBytes,
      'min_memory_gb': minMemoryGb,
      'runtime': runtime,
      'artifact_type': artifactType,
      'revision': revision,
      'supports_text': supportsText,
      'supports_image': supportsImage,
      'supports_audio': supportsAudio,
      'supports_thinking': supportsThinking,
      'max_context_tokens': maxContextTokens,
    };
  }
}

extension on LlmGenerationConfig {
  Map<String, Object?> toNativeMap() {
    return <String, Object?>{
      'temperature': temperature,
      'top_k': topK,
      'top_p': topP,
      'max_tokens': maxTokens,
      'enable_thinking': enableThinking,
    };
  }
}
