import '../../../domain/ai/agent_skill.dart';
import '../../../domain/ai/agent_turn_event.dart';

abstract interface class AgentRuntime {
  Stream<AgentTurnEvent> runTurn({
    required AgentSessionContext context,
    required String userMessage,
  });
}

class AgentSessionContext {
  const AgentSessionContext({
    required this.sessionId,
    this.enabledSkills = const <AgentSkill>[],
    this.allowThinking = false,
  });

  final String sessionId;
  final List<AgentSkill> enabledSkills;
  final bool allowThinking;
}
