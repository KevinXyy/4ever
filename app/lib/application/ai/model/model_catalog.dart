import '../../../domain/ai/model_manifest.dart';

abstract interface class ModelCatalog {
  Future<ModelManifest> load();
}
