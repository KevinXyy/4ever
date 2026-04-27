import Flutter

enum NativeErrorCode: String {
  case modelFileNotFound = "MODEL_FILE_NOT_FOUND"
  case modelHashMismatch = "MODEL_HASH_MISMATCH"
  case modelLoadFailed = "MODEL_LOAD_FAILED"
  case modelUnsupportedDevice = "MODEL_UNSUPPORTED_DEVICE"
  case modelOutOfMemory = "MODEL_OUT_OF_MEMORY"
  case modelRuntimeInternal = "MODEL_RUNTIME_INTERNAL"
  case generationCancelled = "GENERATION_CANCELLED"
  case generationTimeout = "GENERATION_TIMEOUT"
  case generationEmptyOutput = "GENERATION_EMPTY_OUTPUT"
  case nativePermissionDenied = "NATIVE_PERMISSION_DENIED"
  case unknown = "UNKNOWN"
}

func nativeFlutterError(
  _ code: NativeErrorCode,
  message: String,
  details: Any? = nil
) -> FlutterError {
  FlutterError(code: code.rawValue, message: message, details: details)
}
