enum AgentToolResultStatus {
  succeeded,
  failed,
  denied,
}

class AgentToolResult {
  const AgentToolResult({
    required this.callId,
    required this.status,
    required this.summary,
    this.payload = const <String, Object?>{},
    this.errorCode,
    this.safeForPrompt = true,
  });

  final String callId;
  final AgentToolResultStatus status;
  final String summary;
  final Map<String, Object?> payload;
  final String? errorCode;
  final bool safeForPrompt;
}
