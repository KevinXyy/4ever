import '../../../domain/ai/model_manifest_entry.dart';

abstract interface class ModelStoragePaths {
  Future<String> registryFilePath();

  Future<String> modelFilePath(ModelManifestEntry model);
}
