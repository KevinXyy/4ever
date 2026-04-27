import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/model/device_capabilities_reader.dart';
import '../../application/ai/model/model_catalog.dart';
import '../../application/ai/model/model_file_downloader.dart';
import '../../application/ai/model/model_file_verifier.dart';
import '../../application/ai/model/model_lifecycle_service.dart';
import '../../application/ai/model/model_registry_store.dart';
import '../../application/ai/model/model_selection_service.dart';
import '../../application/ai/model/model_storage_paths.dart';
import '../../data/model/application_support_model_storage_paths.dart';
import '../../data/model/asset_model_catalog.dart';
import '../../data/model/background_downloader_model_file_downloader.dart';
import '../../data/model/dart_model_file_verifier.dart';
import '../../data/model/json_model_registry_store.dart';
import '../native/device_capabilities_channel_reader.dart';
import 'native_providers.dart';

final modelCatalogProvider = Provider<ModelCatalog>((Ref ref) {
  return const AssetModelCatalog();
});

final modelSelectionServiceProvider = Provider<ModelSelectionService>((Ref ref) {
  return const ModelSelectionService();
});

final modelStoragePathsProvider = Provider<ModelStoragePaths>((Ref ref) {
  return const ApplicationSupportModelStoragePaths();
});

final modelFileDownloaderProvider = Provider<ModelFileDownloader>((Ref ref) {
  return const BackgroundDownloaderModelFileDownloader();
});

final modelFileVerifierProvider = Provider<ModelFileVerifier>((Ref ref) {
  return const DartModelFileVerifier();
});

final deviceCapabilitiesReaderProvider =
    Provider<DeviceCapabilitiesReader>((Ref ref) {
  return DeviceCapabilitiesChannelReader();
});

final modelRegistryStoreProvider =
    FutureProvider<ModelRegistryStore>((Ref ref) async {
  final paths = ref.watch(modelStoragePathsProvider);
  return JsonModelRegistryStore(
    registryPath: await paths.registryFilePath(),
  );
});

final modelLifecycleServiceProvider =
    FutureProvider<ModelLifecycleService>((Ref ref) async {
  return ModelLifecycleService(
    catalog: ref.watch(modelCatalogProvider),
    deviceCapabilitiesReader: ref.watch(deviceCapabilitiesReaderProvider),
    selectionService: ref.watch(modelSelectionServiceProvider),
    storagePaths: ref.watch(modelStoragePathsProvider),
    downloader: ref.watch(modelFileDownloaderProvider),
    verifier: ref.watch(modelFileVerifierProvider),
    registryStore: await ref.watch(modelRegistryStoreProvider.future),
    runtime: ref.watch(llmRuntimeProvider),
  );
});
