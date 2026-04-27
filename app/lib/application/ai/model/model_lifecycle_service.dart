import '../../../domain/ai/device_capabilities.dart';
import '../../../domain/ai/llm_runtime.dart';
import '../../../domain/ai/model_failure_reason.dart';
import '../../../domain/ai/model_install_progress.dart';
import '../../../domain/ai/model_install_record.dart';
import '../../../domain/ai/model_install_status.dart';
import '../../../domain/ai/model_manifest_entry.dart';
import 'device_capabilities_reader.dart';
import 'model_catalog.dart';
import 'model_file_downloader.dart';
import 'model_file_verifier.dart';
import 'model_registry_store.dart';
import 'model_selection_service.dart';
import 'model_storage_paths.dart';

class ModelLifecycleService {
  const ModelLifecycleService({
    required ModelCatalog catalog,
    required DeviceCapabilitiesReader deviceCapabilitiesReader,
    required ModelSelectionService selectionService,
    required ModelStoragePaths storagePaths,
    required ModelFileDownloader downloader,
    required ModelFileVerifier verifier,
    required ModelRegistryStore registryStore,
    required LlmRuntime runtime,
  }) : _catalog = catalog,
       _deviceCapabilitiesReader = deviceCapabilitiesReader,
       _selectionService = selectionService,
       _storagePaths = storagePaths,
       _downloader = downloader,
       _verifier = verifier,
       _registryStore = registryStore,
       _runtime = runtime;

  static const String smokeTestPrompt = 'Reply with the single word: ready';

  final ModelCatalog _catalog;
  final DeviceCapabilitiesReader _deviceCapabilitiesReader;
  final ModelSelectionService _selectionService;
  final ModelStoragePaths _storagePaths;
  final ModelFileDownloader _downloader;
  final ModelFileVerifier _verifier;
  final ModelRegistryStore _registryStore;
  final LlmRuntime _runtime;

  Stream<ModelInstallProgress> prepareDemoModel({
    String? preferredModelId,
    bool requiresWiFi = true,
  }) async* {
    final capabilities = await _deviceCapabilitiesReader.read();
    final manifest = await _catalog.load();
    final model = _selectionService.select(
      manifest: manifest,
      capabilities: capabilities,
      preferredModelId: preferredModelId,
    );

    yield* installAndLoad(
      model: model,
      capabilities: capabilities,
      requiresWiFi: requiresWiFi,
    );
  }

  Stream<ModelInstallProgress> installAndLoad({
    required ModelManifestEntry model,
    required DeviceCapabilities capabilities,
    bool requiresWiFi = true,
  }) async* {
    final now = DateTime.now().toUtc();
    final targetPath = await _storagePaths.modelFilePath(model);
    var record = ModelInstallRecord(
      modelId: model.id,
      displayName: model.displayName,
      localPath: targetPath,
      sha256: model.sha256,
      sizeBytes: model.sizeBytes,
      sourceCommit: model.sourceCommit,
      status: ModelInstallStatus.notInstalled,
      createdAt: now,
      updatedAt: now,
    );

    if (!model.supportsPlatform(capabilities.platform)) {
      yield _failed(model, ModelFailureReason.unsupportedPlatform);
      return;
    }

    if (capabilities.totalMemoryGb < model.minMemoryGb) {
      yield _failed(model, ModelFailureReason.insufficientMemory);
      return;
    }

    if (capabilities.freeDiskBytes < model.minFreeDiskBytes) {
      yield _failed(model, ModelFailureReason.insufficientDisk);
      return;
    }

    final existingFileIsUsable = await _existingFileIsUsable(
      model: model,
      targetPath: targetPath,
    );
    if (!existingFileIsUsable) {
      record = record.copyWith(
        status: ModelInstallStatus.downloading,
        updatedAt: DateTime.now().toUtc(),
      );
      await _registryStore.upsert(record);
      yield ModelInstallProgress(
        modelId: model.id,
        status: ModelInstallStatus.downloading,
        progress: 0,
      );

      await _downloader.download(
        model: model,
        destinationPath: targetPath,
        requiresWiFi: requiresWiFi,
      );

      record = record.copyWith(
        status: ModelInstallStatus.verifying,
        updatedAt: DateTime.now().toUtc(),
      );
      await _registryStore.upsert(record);
      yield ModelInstallProgress(
        modelId: model.id,
        status: ModelInstallStatus.verifying,
      );

      if (model.sha256 != 'TO_BE_FILLED') {
        final hashMatches = await _verifier.verifySha256(
          path: targetPath,
          expectedSha256: model.sha256,
        );
        if (!hashMatches) {
          final failed = record.copyWith(
            status: ModelInstallStatus.failed,
            updatedAt: DateTime.now().toUtc(),
            failureReason: ModelFailureReason.hashMismatch,
          );
          await _registryStore.upsert(failed);
          yield _failed(model, ModelFailureReason.hashMismatch);
          return;
        }
      }
    }

    record = record.copyWith(
      status: ModelInstallStatus.installed,
      updatedAt: DateTime.now().toUtc(),
    );
    await _registryStore.upsert(record);
    yield ModelInstallProgress(
      modelId: model.id,
      status: record.status,
      progress: record.status == ModelInstallStatus.installed ? 1 : null,
    );

    yield ModelInstallProgress(
      modelId: model.id,
      status: ModelInstallStatus.loading,
    );
    await _registryStore.upsert(
      record.copyWith(
        status: ModelInstallStatus.loading,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    await _runtime.initialize(model.toLlmModelConfig(targetPath));
    final response = await _runtime
        .generateOnce(
          prompt: smokeTestPrompt,
          config: model.defaultGenerationConfig,
        )
        .timeout(const Duration(seconds: 30));

    if (!response.text.toLowerCase().contains('ready')) {
      final failed = record.copyWith(
        status: ModelInstallStatus.failed,
        updatedAt: DateTime.now().toUtc(),
        failureReason: ModelFailureReason.smokeTestFailed,
        errorMessage: 'Smoke test did not return ready.',
      );
      await _registryStore.upsert(failed);
      yield _failed(model, ModelFailureReason.smokeTestFailed);
      return;
    }

    await _registryStore.upsert(
      record.copyWith(
        status: ModelInstallStatus.ready,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    yield ModelInstallProgress(
      modelId: model.id,
      status: ModelInstallStatus.ready,
      progress: 1,
    );
  }

  Future<bool> _existingFileIsUsable({
    required ModelManifestEntry model,
    required String targetPath,
  }) async {
    if (await _verifier.exists(targetPath)) {
      final size = await _verifier.length(targetPath);
      if (size == model.sizeBytes || model.sha256 == 'TO_BE_FILLED') {
        return true;
      }
    }
    return false;
  }

  ModelInstallProgress _failed(
    ModelManifestEntry model,
    ModelFailureReason reason,
  ) {
    return ModelInstallProgress(
      modelId: model.id,
      status: ModelInstallStatus.failed,
      failureReason: reason,
    );
  }
}
