class DeviceCapabilities {
  const DeviceCapabilities({
    required this.platform,
    required this.totalMemoryGb,
    required this.freeDiskBytes,
    this.supportsGpu = false,
    this.supportsNpu = false,
    this.deviceModel,
  });

  final String platform;
  final int totalMemoryGb;
  final int freeDiskBytes;
  final bool supportsGpu;
  final bool supportsNpu;
  final String? deviceModel;
}
