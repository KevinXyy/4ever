import '../privacy/sensitivity_level.dart';
import 'agent_tool_call.dart';
import 'agent_tool_result.dart';

abstract interface class AgentTool {
  AgentToolDefinition get definition;

  Future<AgentToolResult> execute(
    AgentToolCall call,
    AgentToolContext context,
  );
}

class AgentToolDefinition {
  const AgentToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.outputSensitivity,
    this.requiresUserConfirmation = false,
    this.resultAllowedInPrompt = true,
  });

  final String name;
  final String description;
  final Map<String, Object?> inputSchema;
  final SensitivityLevel outputSensitivity;
  final bool requiresUserConfirmation;
  final bool resultAllowedInPrompt;
}

class AgentToolContext {
  const AgentToolContext({
    required this.sessionId,
    required this.now,
    this.consentedScopes = const <String>{},
  });

  final String sessionId;
  final DateTime now;
  final Set<String> consentedScopes;
}
