import '../../application/ai/model/device_capabilities_reader.dart';
import '../../domain/ai/device_capabilities.dart';
import 'generated/device_capabilities_api.g.dart' as pigeon;

class DeviceCapabilitiesChannelReader implements DeviceCapabilitiesReader {
  DeviceCapabilitiesChannelReader({pigeon.DeviceCapabilitiesHostApi? api})
    : _api = api ?? pigeon.DeviceCapabilitiesHostApi();

  final pigeon.DeviceCapabilitiesHostApi _api;

  @override
  Future<DeviceCapabilities> read() async {
    final result = await _api.read();

    return DeviceCapabilities(
      platform: result.platform,
      totalMemoryGb: result.totalMemoryGb,
      freeDiskBytes: result.freeDiskBytes,
      supportsGpu: result.supportsGpu,
      supportsNpu: result.supportsNpu,
      deviceModel: result.deviceModel,
    );
  }
}
