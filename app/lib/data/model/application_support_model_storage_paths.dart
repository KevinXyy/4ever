import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../application/ai/model/model_storage_paths.dart';
import '../../domain/ai/model_manifest_entry.dart';

class ApplicationSupportModelStoragePaths implements ModelStoragePaths {
  const ApplicationSupportModelStoragePaths();

  @override
  Future<String> registryFilePath() async {
    final root = await getApplicationSupportDirectory();
    return p.join(root.path, 'model_registry.json');
  }

  @override
  Future<String> modelFilePath(ModelManifestEntry model) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      p.join(root.path, 'models', model.id, model.sourceCommit),
    );
    await directory.create(recursive: true);
    return p.join(directory.path, model.fileName);
  }
}
