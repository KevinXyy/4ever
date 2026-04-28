import Flutter
import UIKit

final class NativeBridgeRegistry {
  private let llmRuntime: LlmRuntimeHostApiAdapter
  private let healthData: HealthKitHostApiAdapter
  private let crypto: CryptoHostApiAdapter
  private let backgroundTask: BackgroundTaskHostApiAdapter
  private let deviceCapabilities: DeviceCapabilitiesHostApiAdapter

  init() {
    llmRuntime = LlmRuntimeHostApiAdapter()
    healthData = HealthKitHostApiAdapter()
    crypto = CryptoHostApiAdapter()
    backgroundTask = BackgroundTaskHostApiAdapter()
    deviceCapabilities = DeviceCapabilitiesHostApiAdapter()
  }

  func register(with messenger: FlutterBinaryMessenger) {
    llmRuntime.register(with: messenger)
    healthData.register(with: messenger)
    crypto.register(with: messenger)
    backgroundTask.register(with: messenger)
    deviceCapabilities.register(with: messenger)
  }
}
