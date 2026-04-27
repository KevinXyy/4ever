import 'agent_tool_call.dart';
import 'agent_tool_result.dart';

enum AgentTurnEventType {
  textDelta,
  thinkingDelta,
  toolCallStarted,
  toolCallCompleted,
  warning,
  done,
}

class AgentTurnEvent {
  const AgentTurnEvent({
    required this.type,
    this.text,
    this.toolCall,
    this.toolResult,
  });

  final AgentTurnEventType type;
  final String? text;
  final AgentToolCall? toolCall;
  final AgentToolResult? toolResult;
}
