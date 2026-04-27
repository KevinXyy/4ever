import '../../../domain/ai/model_manifest_entry.dart';

typedef ModelDownloadProgressCallback = void Function(double progress);

abstract interface class ModelFileDownloader {
  Future<String> download({
    required ModelManifestEntry model,
    required String destinationPath,
    required bool requiresWiFi,
    ModelDownloadProgressCallback? onProgress,
  });
}
