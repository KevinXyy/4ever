import 'model_manifest_entry.dart';

class ModelManifest {
  const ModelManifest({required this.schemaVersion, required this.models});

  final String schemaVersion;
  final List<ModelManifestEntry> models;

  ModelManifestEntry byId(String id) {
    return models.firstWhere((model) => model.id == id);
  }

  static ModelManifest fromJson(Map<String, Object?> json) {
    final modelsJson = json['models'];
    if (modelsJson is! List<Object?>) {
      throw const FormatException('Missing models list.');
    }

    return ModelManifest(
      schemaVersion: json['schema_version']! as String,
      models: modelsJson
          .map(
            (item) =>
                ModelManifestEntry.fromJson(item! as Map<String, Object?>),
          )
          .toList(),
    );
  }
}
