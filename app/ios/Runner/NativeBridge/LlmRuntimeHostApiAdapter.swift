import Flutter
import Foundation
import CoreMLLLM

final class LlmRuntimeHostApiAdapter: NSObject {
  private var llm: CoreMLLLM?
  private var loadedModelId: String?
  private var state = "unloaded"
  private var lastErrorCode: String?
  private var lastErrorMessage: String?
  private var generationTask: Task<Void, Never>?

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
      generationTask?.cancel()
      generationTask = nil
      result(nil)
    case "unload":
      generationTask?.cancel()
      generationTask = nil
      llm = nil
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
          let localPath = payload["local_path"] as? String,
          let runtime = payload["runtime"] as? String,
          let artifactType = payload["artifact_type"] as? String else {
      result(nativeFlutterError(.unknown, message: "Invalid model config."))
      return
    }

    guard runtime == "coreml_llm", artifactType == "coreml_bundle" else {
      state = "failed"
      lastErrorCode = NativeErrorCode.modelUnsupportedDevice.rawValue
      lastErrorMessage = "iOS Core ML adapter only supports coreml_llm/coreml_bundle."
      result(nativeFlutterError(.modelUnsupportedDevice, message: lastErrorMessage!))
      return
    }

    let directory = URL(fileURLWithPath: localPath, isDirectory: true)
    guard isCoreMlBundleReady(at: directory) else {
      state = "failed"
      lastErrorCode = NativeErrorCode.modelFileNotFound.rawValue
      lastErrorMessage = "CoreML bundle is missing required model files."
      result(nativeFlutterError(.modelFileNotFound, message: lastErrorMessage!))
      return
    }

    state = "loading"
    lastErrorCode = nil
    lastErrorMessage = nil

    Task { [weak self] in
      do {
        let loaded = try await CoreMLLLM.load(from: directory) { status in
          print("[CoreMLLLM] \(status)")
        }
        DispatchQueue.main.async {
          self?.llm = loaded
          self?.loadedModelId = modelId
          self?.state = "ready"
          result(nil)
        }
      } catch {
        DispatchQueue.main.async {
          self?.llm = nil
          self?.loadedModelId = nil
          self?.state = "failed"
          self?.lastErrorCode = NativeErrorCode.modelLoadFailed.rawValue
          self?.lastErrorMessage = String(describing: error)
          result(nativeFlutterError(.modelLoadFailed, message: String(describing: error)))
        }
      }
    }
  }

  private func generateOnce(_ arguments: Any?, result: @escaping FlutterResult) {
    guard state == "ready", let modelId = loadedModelId, let llm else {
      result(nativeFlutterError(.modelLoadFailed, message: "No local model is loaded."))
      return
    }

    guard let payload = arguments as? [String: Any],
          let prompt = payload["prompt"] as? String else {
      result(nativeFlutterError(.unknown, message: "Invalid generation request."))
      return
    }

    let config = payload["config"] as? [String: Any]
    let maxTokens = config?["max_tokens"] as? Int ?? 2048

    generationTask?.cancel()
    generationTask = Task { [weak self] in
      do {
        let text = try await llm.generate(prompt, maxTokens: maxTokens)
        let wasCancelled = Task.isCancelled
        DispatchQueue.main.async {
          guard !wasCancelled else {
            result(nativeFlutterError(.generationCancelled, message: "Generation was cancelled."))
            return
          }
          guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result(nativeFlutterError(.generationEmptyOutput, message: "CoreML-LLM returned empty output."))
            return
          }
          result([
            "text": text,
            "model_id": modelId
          ])
          self?.generationTask = nil
        }
      } catch is CancellationError {
        DispatchQueue.main.async {
          result(nativeFlutterError(.generationCancelled, message: "Generation was cancelled."))
          self?.generationTask = nil
        }
      } catch {
        DispatchQueue.main.async {
          self?.lastErrorCode = NativeErrorCode.modelRuntimeInternal.rawValue
          self?.lastErrorMessage = String(describing: error)
          result(nativeFlutterError(.modelRuntimeInternal, message: String(describing: error)))
          self?.generationTask = nil
        }
      }
    }
  }

  private func statusPayload() -> [String: Any?] {
    [
      "state": state,
      "error_code": lastErrorCode,
      "error_message": lastErrorMessage,
      "used_memory_mb": nil,
      "loaded_model_id": loadedModelId
    ]
  }

  private func isCoreMlBundleReady(at directory: URL) -> Bool {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
          isDirectory.boolValue,
          FileManager.default.fileExists(atPath: directory.appendingPathComponent("model_config.json").path) else {
      return false
    }

    let chunk = directory.appendingPathComponent("chunk1.mlmodelc")
    let model = directory.appendingPathComponent("model.mlmodelc")
    let package = directory.appendingPathComponent("model.mlpackage")
    let tokenizer = directory.appendingPathComponent("hf_model")
    let hasModel = FileManager.default.fileExists(atPath: chunk.path)
      || FileManager.default.fileExists(atPath: model.path)
      || FileManager.default.fileExists(atPath: package.path)
    return hasModel && FileManager.default.fileExists(atPath: tokenizer.path)
  }
}
