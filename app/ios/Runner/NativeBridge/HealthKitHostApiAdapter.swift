import Flutter
import Foundation
import HealthKit

final class HealthKitHostApiAdapter: NSObject {
  private let healthStore = HKHealthStore()

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.gemmalocal.native/health_data",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(HKHealthStore.isHealthDataAvailable())
    case "requestReadPermissions":
      requestReadPermissions(call.arguments, result: result)
    case "readSamples":
      result(nativeFlutterError(.modelRuntimeInternal, message: "HealthKit sample import is not implemented yet."))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestReadPermissions(_ arguments: Any?, result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }

    let metricTypes = arguments as? [String] ?? []
    let readTypes = Set(metricTypes.compactMap(healthKitType(for:)))

    healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
      if let error {
        result(nativeFlutterError(.nativePermissionDenied, message: error.localizedDescription))
        return
      }
      result(success)
    }
  }

  private func healthKitType(for metricType: String) -> HKObjectType? {
    switch metricType {
    case "steps":
      return HKObjectType.quantityType(forIdentifier: .stepCount)
    case "activeEnergy":
      return HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
    case "heartRate":
      return HKObjectType.quantityType(forIdentifier: .heartRate)
    case "restingHeartRate":
      return HKObjectType.quantityType(forIdentifier: .restingHeartRate)
    case "hrv":
      return HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
    case "weight":
      return HKObjectType.quantityType(forIdentifier: .bodyMass)
    case "sleepSession", "sleepStage":
      return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    case "mindfulMinutes":
      return HKObjectType.categoryType(forIdentifier: .mindfulSession)
    case "exerciseSession":
      return HKObjectType.workoutType()
    default:
      return nil
    }
  }
}
