import 'package:pigeon/pigeon.dart';

class NativeDeviceCapabilities {
  NativeDeviceCapabilities({
    required this.platform,
    required this.totalMemoryGb,
    required this.freeDiskBytes,
    required this.supportsGpu,
    required this.supportsNpu,
    this.deviceModel,
  });

  String platform;
  int totalMemoryGb;
  int freeDiskBytes;
  bool supportsGpu;
  bool supportsNpu;
  String? deviceModel;
}

@HostApi()
abstract class DeviceCapabilitiesHostApi {
  NativeDeviceCapabilities read();
}
