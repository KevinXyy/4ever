import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_local/application/ai/model/device_capabilities_reader.dart';
import 'package:gemma_local/application/ai/model/model_catalog.dart';
import 'package:gemma_local/application/ai/model/model_file_downloader.dart';
import 'package:gemma_local/application/ai/model/model_lifecycle_service.dart';
import 'package:gemma_local/application/ai/model/model_registry_store.dart';
import 'package:gemma_local/application/ai/model/model_selection_service.dart';
import 'package:gemma_local/application/ai/model/model_storage_paths.dart';
import 'package:gemma_local/data/model/asset_model_catalog.dart';
import 'package:gemma_local/data/model/dart_model_file_verifier.dart';
import 'package:gemma_local/data/model/json_model_registry_store.dart';
import 'package:gemma_local/domain/ai/device_capabilities.dart';
import 'package:gemma_local/domain/ai/llm_generation_config.dart';
import 'package:gemma_local/domain/ai/llm_model_config.dart';
import 'package:gemma_local/domain/ai/llm_response.dart';
import 'package:gemma_local/domain/ai/llm_runtime.dart';
import 'package:gemma_local/domain/ai/llm_runtime_status.dart';
import 'package:gemma_local/domain/ai/llm_token_event.dart';
import 'package:gemma_local/domain/ai/model_install_record.dart';
import 'package:gemma_local/domain/ai/model_install_status.dart';
import 'package:gemma_local/domain/ai/model_manifest.dart';
import 'package:gemma_local/domain/ai/model_manifest_entry.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asset manifest parses Gemma 4 E2B and E4B', () async {
    final manifest = await const AssetModelCatalog().load();

    expect(manifest.schemaVersion, '1.0');
    expect(manifest.byId('gemma-4-e2b-it').supportsPlatform('ios'), isTrue);
    expect(manifest.byId('gemma-4-e4b-it').isDefault, isTrue);
  });

  test('selection picks E4B on high-memory devices and E2B on 8GB devices',
      () async {
    final manifest = await const AssetModelCatalog().load();
    const selection = ModelSelectionService();

    final highMemoryModel = selection.select(
      manifest: manifest,
      capabilities: const DeviceCapabilities(
        platform: 'ios',
        totalMemoryGb: 16,
        freeDiskBytes: 9000000000,
      ),
    );
    final lowMemoryModel = selection.select(
      manifest: manifest,
      capabilities: const DeviceCapabilities(
        platform: 'ios',
        totalMemoryGb: 8,
        freeDiskBytes: 9000000000,
      ),
    );

    expect(highMemoryModel.id, 'gemma-4-e4b-it');
    expect(lowMemoryModel.id, 'gemma-4-e2b-it');
  });

  test('Dart verifier checks SHA-256', () async {
    final tempDir = await Directory.systemTemp.createTemp('model_verifier_');
    addTearDown(() async => tempDir.delete(recursive: true));
    final file = File(p.join(tempDir.path, 'sample.bin'));
    await file.writeAsString('ready');

    final expectedHash = sha256.convert(utf8.encode('ready')).toString();
    final verifier = const DartModelFileVerifier();

    expect(
      await verifier.verifySha256(
        path: file.path,
        expectedSha256: expectedHash,
      ),
      isTrue,
    );
  });

  test('JSON registry store persists model install records', () async {
    final tempDir = await Directory.systemTemp.createTemp('model_registry_');
    addTearDown(() async => tempDir.delete(recursive: true));
    final store = JsonModelRegistryStore(
      registryPath: p.join(tempDir.path, 'model_registry.json'),
    );
    final now = DateTime.utc(2026, 4, 27);
    final record = ModelInstallRecord(
      modelId: 'gemma-4-e2b-it',
      displayName: 'Gemma 4 E2B',
      localPath: '/models/gemma-4-E2B-it.litertlm',
      sha256: 'TO_BE_FILLED',
      sizeBytes: 1,
      sourceCommit: 'commit',
      status: ModelInstallStatus.installed,
      createdAt: now,
      updatedAt: now,
    );

    await store.upsert(record);

    expect((await store.read('gemma-4-e2b-it'))?.status,
        ModelInstallStatus.installed);
  });

  test('lifecycle downloads, registers, initializes, and smoke tests',
      () async {
    final tempDir = await Directory.systemTemp.createTemp('model_lifecycle_');
    addTearDown(() async => tempDir.delete(recursive: true));
    final model = _testModel();
    final registry = _MemoryRegistryStore();
    final runtime = _FakeLlmRuntime();
    final service = ModelLifecycleService(
      catalog: _FakeCatalog(ModelManifest(schemaVersion: '1.0', models: [model])),
      deviceCapabilitiesReader: const _FakeDeviceCapabilitiesReader(),
      selectionService: const ModelSelectionService(),
      storagePaths: _FakeStoragePaths(
        p.join(tempDir.path, model.fileName),
      ),
      downloader: const _FakeDownloader(),
      verifier: const DartModelFileVerifier(),
      registryStore: registry,
      runtime: runtime,
    );

    final progress = await service.prepareDemoModel().toList();

    expect(progress.map((item) => item.status), containsAllInOrder([
      ModelInstallStatus.downloading,
      ModelInstallStatus.verifying,
      ModelInstallStatus.installed,
      ModelInstallStatus.loading,
      ModelInstallStatus.ready,
    ]));
    expect(runtime.initializedModelId, model.id);
    expect((await registry.read(model.id))?.status, ModelInstallStatus.ready);
  });
}

ModelManifestEntry _testModel() {
  return const ModelManifestEntry(
    id: 'gemma-4-e2b-it',
    displayName: 'Gemma 4 E2B',
    provider: 'litert-community',
    modelId: 'litert-community/gemma-4-E2B-it-litert-lm',
    fileName: 'gemma-4-E2B-it.litertlm',
    downloadUrl: 'https://example.test/model.litertlm',
    sourceCommit: 'commit',
    sha256: 'TO_BE_FILLED',
    sizeBytes: 5,
    minMemoryGb: 8,
    minFreeDiskBytes: 10,
    modalities: <String>['text', 'image', 'audio'],
    supportsThinking: true,
    maxContextTokens: 32000,
    defaultGenerationConfig: LlmGenerationConfig(
      topK: 64,
      topP: 0.95,
      temperature: 1,
      maxTokens: 4000,
      enableThinking: true,
    ),
    accelerators: <String>['gpu', 'cpu'],
    isDefault: true,
    platforms: <String>['ios', 'android'],
    selectionPriority: 10,
  );
}

class _FakeCatalog implements ModelCatalog {
  const _FakeCatalog(this.manifest);

  final ModelManifest manifest;

  @override
  Future<ModelManifest> load() async => manifest;
}

class _FakeDeviceCapabilitiesReader implements DeviceCapabilitiesReader {
  const _FakeDeviceCapabilitiesReader();

  @override
  Future<DeviceCapabilities> read() async {
    return const DeviceCapabilities(
      platform: 'ios',
      totalMemoryGb: 16,
      freeDiskBytes: 100,
    );
  }
}

class _FakeStoragePaths implements ModelStoragePaths {
  const _FakeStoragePaths(this.path);

  final String path;

  @override
  Future<String> modelFilePath(ModelManifestEntry model) async => path;

  @override
  Future<String> registryFilePath() async {
    return p.join(p.dirname(path), 'model_registry.json');
  }
}

class _FakeDownloader implements ModelFileDownloader {
  const _FakeDownloader();

  @override
  Future<String> download({
    required ModelManifestEntry model,
    required String destinationPath,
    required bool requiresWiFi,
    ModelDownloadProgressCallback? onProgress,
  }) async {
    final file = File(destinationPath);
    await file.parent.create(recursive: true);
    await file.writeAsString('ready');
    onProgress?.call(1);
    return destinationPath;
  }
}

class _MemoryRegistryStore implements ModelRegistryStore {
  final Map<String, ModelInstallRecord> _records =
      <String, ModelInstallRecord>{};

  @override
  Future<List<ModelInstallRecord>> readAll() async {
    return _records.values.toList();
  }

  @override
  Future<ModelInstallRecord?> read(String modelId) async {
    return _records[modelId];
  }

  @override
  Future<void> upsert(ModelInstallRecord record) async {
    _records[record.modelId] = record;
  }
}

class _FakeLlmRuntime implements LlmRuntime {
  String? initializedModelId;

  @override
  Future<void> cancel() async {}

  @override
  Future<LlmResponse> generateOnce({
    required String prompt,
    List<Object> attachments = const <Object>[],
    LlmGenerationConfig config = const LlmGenerationConfig(),
  }) async {
    return LlmResponse(
      text: prompt == ModelLifecycleService.smokeTestPrompt ? 'ready' : '',
      modelId: initializedModelId ?? 'unloaded',
    );
  }

  @override
  Stream<LlmTokenEvent> generateStream({
    required String prompt,
    List<Object> attachments = const <Object>[],
    LlmGenerationConfig config = const LlmGenerationConfig(),
  }) {
    return const Stream<LlmTokenEvent>.empty();
  }

  @override
  Future<LlmRuntimeStatus> getStatus() async {
    return LlmRuntimeStatus(
      state: initializedModelId == null ? 'unloaded' : 'ready',
      loadedModelId: initializedModelId,
    );
  }

  @override
  Future<void> initialize(LlmModelConfig config) async {
    initializedModelId = config.modelId;
  }

  @override
  Future<void> unload() async {
    initializedModelId = null;
  }
}
