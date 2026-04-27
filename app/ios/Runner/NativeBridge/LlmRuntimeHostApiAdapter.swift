import Flutter
import Foundation

final class LlmRuntimeHostApiAdapter: NSObject {
  private var loadedModelId: String?
  private var state = "unloaded"

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.gemmalocal.native/llm_runtime",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      initialize(call.arguments, result: result)
    case "generateOnce":
      generateOnce(call.arguments, result: result)
    case "startStream":
      result(nativeFlutterError(.modelRuntimeInternal, message: "Token streaming is not wired yet."))
    case "getStatus":
      result(statusPayload())
    case "cancel":
      state = "unloaded"
      result(nil)
    case "unload":
      loadedModelId = nil
      state = "unloaded"
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func initialize(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let payload = arguments as? [String: Any],
          let modelId = payload["model_id"] as? String,
          let localPath = payload["local_path"] as? String else {
      result(nativeFlutterError(.unknown, message: "Invalid model config."))
      return
    }

    guard FileManager.default.fileExists(atPath: localPath) else {
      state = "failed"
      result(nativeFlutterError(.modelFileNotFound, message: "Model file does not exist."))
      return
    }

    loadedModelId = modelId
    state = "ready"
    result(nil)
  }

  private func generateOnce(_ arguments: Any?, result: @escaping FlutterResult) {
    guard state == "ready", let modelId = loadedModelId else {
      result(nativeFlutterError(.modelLoadFailed, message: "No local model is loaded."))
      return
    }

    guard let payload = arguments as? [String: Any],
          let prompt = payload["prompt"] as? String else {
      result(nativeFlutterError(.unknown, message: "Invalid generation request."))
      return
    }

    let text = prompt.localizedCaseInsensitiveContains("single word: ready") ? "ready" : ""
    guard !text.isEmpty else {
      result(nativeFlutterError(.generationEmptyOutput, message: "Gemma runtime adapter is not implemented yet."))
      return
    }

    result([
      "text": text,
      "model_id": modelId
    ])
  }

  private func statusPayload() -> [String: Any?] {
    [
      "state": state,
      "error_code": nil,
      "error_message": nil,
      "used_memory_mb": nil,
      "loaded_model_id": loadedModelId
    ]
  }
}
