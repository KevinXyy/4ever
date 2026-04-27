import 'dart:convert';
import 'dart:io';

import '../../application/ai/model/model_registry_store.dart';
import '../../domain/ai/model_install_record.dart';

class JsonModelRegistryStore implements ModelRegistryStore {
  const JsonModelRegistryStore({required this.registryPath});

  final String registryPath;

  @override
  Future<List<ModelInstallRecord>> readAll() async {
    final file = File(registryPath);
    if (!await file.exists()) {
      return <ModelInstallRecord>[];
    }

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Model registry root must be a JSON object.');
    }

    final recordsJson = decoded['records'];
    if (recordsJson is! List<Object?>) {
      return <ModelInstallRecord>[];
    }

    return recordsJson
        .map(
          (recordJson) =>
              ModelInstallRecord.fromJson(recordJson! as Map<String, Object?>),
        )
        .toList();
  }

  @override
  Future<ModelInstallRecord?> read(String modelId) async {
    final records = await readAll();
    for (final record in records) {
      if (record.modelId == modelId) {
        return record;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(ModelInstallRecord record) async {
    final records = await readAll();
    final index = records.indexWhere((item) => item.modelId == record.modelId);
    if (index == -1) {
      records.add(record);
    } else {
      records[index] = record;
    }

    await _write(records);
  }

  Future<void> _write(List<ModelInstallRecord> records) async {
    final file = File(registryPath);
    await file.parent.create(recursive: true);
    final tempFile = File('$registryPath.tmp');
    const encoder = JsonEncoder.withIndent('  ');
    final payload = <String, Object?>{
      'schema_version': '1.0',
      'records': records.map((record) => record.toJson()).toList(),
    };
    await tempFile.writeAsString(encoder.convert(payload));
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(registryPath);
  }
}
