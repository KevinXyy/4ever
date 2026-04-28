import Flutter
import Foundation
import UIKit

final class DeviceCapabilitiesHostApiAdapter: NSObject, DeviceCapabilitiesHostApi {
  func register(with messenger: FlutterBinaryMessenger) {
    DeviceCapabilitiesHostApiSetup.setUp(binaryMessenger: messenger, api: self)
  }

  func read() throws -> NativeDeviceCapabilities {
    return NativeDeviceCapabilities(
      platform: "ios",
      totalMemoryGb: physicalMemoryGb(),
      freeDiskBytes: freeDiskBytes(),
      supportsGpu: false,
      supportsNpu: false,
      deviceModel: deviceModel()
    )
  }

  private func physicalMemoryGb() -> Int64 {
    let bytesPerGb = 1024.0 * 1024.0 * 1024.0
    let memoryGb = Double(ProcessInfo.processInfo.physicalMemory) / bytesPerGb
    return Int64(ceil(memoryGb))
  }

  private func freeDiskBytes() -> Int64 {
    do {
      let values = try FileManager.default.attributesOfFileSystem(
        forPath: NSHomeDirectory()
      )
      if let freeSize = values[.systemFreeSize] as? NSNumber {
        return freeSize.int64Value
      }
      if let freeSize = values[.systemFreeSize] as? Int64 {
        return freeSize
      }
      return 0
    } catch {
      return 0
    }
  }

  private func deviceModel() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)

    let mirror = Mirror(reflecting: systemInfo.machine)
    let identifier = mirror.children.reduce(into: "") { result, element in
      guard let value = element.value as? Int8, value != 0 else {
        return
      }
      result.append(String(UnicodeScalar(UInt8(value))))
    }

    return identifier.isEmpty ? UIDevice.current.model : identifier
  }
}
