import 'package:flutter/services.dart';

import '../../application/ai/model/device_capabilities_reader.dart';
import '../../domain/ai/device_capabilities.dart';
import 'native_channel_names.dart';

class DeviceCapabilitiesChannelReader implements DeviceCapabilitiesReader {
  DeviceCapabilitiesChannelReader({MethodChannel? methodChannel})
    : _methodChannel =
          methodChannel ??
          const MethodChannel(NativeChannelNames.deviceCapabilities);

  final MethodChannel _methodChannel;

  @override
  Future<DeviceCapabilities> read() async {
    final result = await _methodChannel.invokeMapMethod<String, Object?>(
      'read',
    );
    if (result == null) {
      throw StateError('Device capabilities API returned null.');
    }

    return DeviceCapabilities(
      platform: result['platform']! as String,
      totalMemoryGb: result['total_memory_gb']! as int,
      freeDiskBytes: result['free_disk_bytes']! as int,
      supportsGpu: result['supports_gpu'] as bool? ?? false,
      supportsNpu: result['supports_npu'] as bool? ?? false,
      deviceModel: result['device_model'] as String?,
    );
  }
}
