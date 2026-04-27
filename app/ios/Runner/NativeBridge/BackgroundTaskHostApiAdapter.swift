import BackgroundTasks
import Flutter
import Foundation

final class BackgroundTaskHostApiAdapter: NSObject {
  static let refreshIdentifier = "com.gemmalocal.refresh"

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.gemmalocal.native/background_task",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler(handle)
  }

  func registerScheduler() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: Self.refreshIdentifier,
      using: nil
    ) { task in
      task.setTaskCompleted(success: true)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "registerBackgroundRefresh":
      scheduleRefresh()
      result(nil)
    case "cancelBackgroundRefresh":
      BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshIdentifier)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func scheduleRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: Self.refreshIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
    try? BGTaskScheduler.shared.submit(request)
  }
}
