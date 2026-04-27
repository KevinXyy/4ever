enum AgentSkillSource {
  builtIn,
  bundled,
  userImported,
  remote,
}

class AgentSkill {
  const AgentSkill({
    required this.id,
    required this.displayName,
    required this.description,
    required this.instructions,
    required this.enabledToolNames,
    required this.source,
    this.enabled = true,
    this.requiresUserApproval = false,
  });

  final String id;
  final String displayName;
  final String description;
  final String instructions;
  final List<String> enabledToolNames;
  final AgentSkillSource source;
  final bool enabled;
  final bool requiresUserApproval;
}
