import 'llm_generation_config.dart';
import 'llm_model_config.dart';

class ModelManifestEntry {
  const ModelManifestEntry({
    required this.id,
    required this.displayName,
    required this.provider,
    required this.modelId,
    required this.runtime,
    required this.artifactType,
    required this.revision,
    required this.fileName,
    required this.downloadUrl,
    required this.sourceCommit,
    required this.sha256,
    required this.sizeBytes,
    required this.minMemoryGb,
    required this.minFreeDiskBytes,
    required this.modalities,
    required this.supportsThinking,
    required this.maxContextTokens,
    required this.defaultGenerationConfig,
    required this.accelerators,
    required this.isDefault,
    required this.platforms,
    required this.selectionPriority,
    this.repoId,
    this.allowPatterns = const <String>[],
    this.visionAccelerator,
  });

  final String id;
  final String displayName;
  final String provider;
  final String modelId;
  final String runtime;
  final String artifactType;
  final String revision;
  final String fileName;
  final String downloadUrl;
  final String sourceCommit;
  final String sha256;
  final int sizeBytes;
  final int minMemoryGb;
  final int minFreeDiskBytes;
  final List<String> modalities;
  final bool supportsThinking;
  final int maxContextTokens;
  final LlmGenerationConfig defaultGenerationConfig;
  final List<String> accelerators;
  final String? visionAccelerator;
  final bool isDefault;
  final List<String> platforms;
  final int selectionPriority;
  final String? repoId;
  final List<String> allowPatterns;

  bool get supportsText => modalities.contains('text');

  bool get supportsImage => modalities.contains('image');

  bool get supportsAudio => modalities.contains('audio');

  bool get isBundleArtifact => artifactType == 'coreml_bundle';

  bool supportsPlatform(String platform) {
    return platforms.contains(platform.toLowerCase());
  }

  LlmModelConfig toLlmModelConfig(String localPath) {
    return LlmModelConfig(
      modelId: id,
      localPath: localPath,
      sha256: sha256,
      sizeBytes: sizeBytes,
      minMemoryGb: minMemoryGb,
      runtime: runtime,
      artifactType: artifactType,
      revision: revision,
      supportsText: supportsText,
      supportsImage: supportsImage,
      supportsAudio: supportsAudio,
      supportsThinking: supportsThinking,
      maxContextTokens: maxContextTokens,
    );
  }

  static ModelManifestEntry fromJson(Map<String, Object?> json) {
    final generationConfig = json['default_generation_config'];
    if (generationConfig is! Map<String, Object?>) {
      throw const FormatException('Missing default_generation_config.');
    }

    return ModelManifestEntry(
      id: json['id']! as String,
      displayName: json['display_name']! as String,
      provider: json['provider']! as String,
      modelId: json['model_id']! as String,
      runtime: json['runtime'] as String? ?? 'litert_lm',
      artifactType: json['artifact_type'] as String? ?? 'litertlm_file',
      revision: json['revision'] as String? ?? json['source_commit']! as String,
      fileName: json['file_name'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
      sourceCommit:
          json['source_commit'] as String? ?? json['revision']! as String,
      sha256: json['sha256'] as String? ?? 'BUNDLE_READINESS_CHECK',
      sizeBytes: json['size_bytes']! as int,
      minMemoryGb: json['min_memory_gb']! as int,
      minFreeDiskBytes: json['min_free_disk_bytes']! as int,
      modalities: _stringList(json['modalities']),
      supportsThinking: json['supports_thinking']! as bool,
      maxContextTokens: json['max_context_tokens']! as int,
      defaultGenerationConfig: LlmGenerationConfig(
        temperature: (generationConfig['temperature']! as num).toDouble(),
        topK: generationConfig['top_k']! as int,
        topP: (generationConfig['top_p']! as num).toDouble(),
        maxTokens: generationConfig['max_tokens']! as int,
        enableThinking: json['supports_thinking']! as bool,
      ),
      accelerators: _stringList(json['accelerators']),
      visionAccelerator: json['vision_accelerator'] as String?,
      isDefault: json['default']! as bool,
      platforms: _stringList(json['platforms']),
      selectionPriority: json['selection_priority']! as int,
      repoId: json['repo_id'] as String?,
      allowPatterns: json.containsKey('allow_patterns')
          ? _stringList(json['allow_patterns'])
          : const <String>[],
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List<Object?>) {
      throw const FormatException('Expected a string list.');
    }

    return value.cast<String>();
  }
}
