import '../../../domain/ai/model_install_record.dart';

abstract interface class ModelRegistryStore {
  Future<List<ModelInstallRecord>> readAll();

  Future<ModelInstallRecord?> read(String modelId);

  Future<void> upsert(ModelInstallRecord record);
}
