import '../../../domain/ai/device_capabilities.dart';

abstract interface class DeviceCapabilitiesReader {
  Future<DeviceCapabilities> read();
}
