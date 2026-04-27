class AgentToolCall {
  const AgentToolCall({
    required this.id,
    required this.name,
    this.arguments = const <String, Object?>{},
  });

  final String id;
  final String name;
  final Map<String, Object?> arguments;
}
