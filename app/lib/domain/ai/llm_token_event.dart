class LlmTokenEvent {
  const LlmTokenEvent({
    required this.requestId,
    required this.type,
    this.text,
    this.errorCode,
  });

  final String requestId;
  final String type;
  final String? text;
  final String? errorCode;
}
