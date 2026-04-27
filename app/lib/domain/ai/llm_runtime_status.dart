class LlmRuntimeStatus {
  const LlmRuntimeStatus({
    required this.state,
    this.errorCode,
    this.errorMessage,
    this.usedMemoryMb,
    this.loadedModelId,
  });

  final String state;
  final String? errorCode;
  final String? errorMessage;
  final int? usedMemoryMb;
  final String? loadedModelId;
}
