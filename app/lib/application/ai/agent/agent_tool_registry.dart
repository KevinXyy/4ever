import '../../../domain/ai/agent_tool.dart';

abstract interface class AgentToolRegistry {
  List<AgentToolDefinition> listDefinitions();

  AgentTool? findByName(String name);
}
