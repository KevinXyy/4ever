import 'dart:convert';

import 'package:flutter/services.dart';

import '../../application/ai/model/model_catalog.dart';
import '../../domain/ai/model_manifest.dart';

class AssetModelCatalog implements ModelCatalog {
  const AssetModelCatalog({
    AssetBundle? assetBundle,
    this.assetPath = 'assets/model_manifest.json',
  }) : _assetBundle = assetBundle;

  final AssetBundle? _assetBundle;
  final String assetPath;

  @override
  Future<ModelManifest> load() async {
    final bundle = _assetBundle ?? rootBundle;
    final manifestText = await bundle.loadString(assetPath);
    final decoded = jsonDecode(manifestText);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Model manifest root must be a JSON object.');
    }

    return ModelManifest.fromJson(decoded);
  }
}
