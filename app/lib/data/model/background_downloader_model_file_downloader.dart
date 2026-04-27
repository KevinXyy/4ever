import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as p;

import '../../application/ai/model/model_file_downloader.dart';
import '../../domain/ai/model_manifest_entry.dart';

class BackgroundDownloaderModelFileDownloader implements ModelFileDownloader {
  const BackgroundDownloaderModelFileDownloader({
    FileDownloader? fileDownloader,
  }) : _fileDownloader = fileDownloader;

  final FileDownloader? _fileDownloader;

  @override
  Future<String> download({
    required ModelManifestEntry model,
    required String destinationPath,
    required bool requiresWiFi,
    ModelDownloadProgressCallback? onProgress,
  }) async {
    final downloader = _fileDownloader ?? FileDownloader();
    final task = DownloadTask(
      url: model.downloadUrl,
      filename: p.basename(destinationPath),
      directory: p.dirname(destinationPath),
      baseDirectory: BaseDirectory.root,
      group: 'models',
      updates: Updates.statusAndProgress,
      requiresWiFi: requiresWiFi,
      retries: 3,
      allowPause: true,
      displayName: model.displayName,
      metaData: model.id,
    );

    final status = await downloader.download(task, onProgress: onProgress);
    if (status.status != TaskStatus.complete) {
      throw StateError(
        'Model download failed with status ${status.status.name}.',
      );
    }

    return destinationPath;
  }
}
