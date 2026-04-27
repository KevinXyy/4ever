# Agent Skills Architecture

This project borrows the Agent Skills idea from Google AI Edge Gallery, but
adapts it for a Flutter, iOS-first, privacy-first health app.

## Reference

Gallery's useful pattern is:

```text
Skill metadata
  -> system prompt augmentation
  -> LiteRT-LM tool declarations
  -> tool execution
  -> structured tool result
  -> model follow-up response
```

The parts worth borrowing are:

- explicit skill metadata and instructions
- tool declarations separate from tool execution
- a registry of enabled tools
- model-visible tool results
- progress events that the UI can render
- constrained decoding for tool calls where the runtime supports it

The parts we should not copy directly are:

- Android-only Compose/Hilt/DataStore architecture
- arbitrary remote skill execution as a default product behavior
- JS skills that can call external services without product-level review
- direct coupling between tool execution and a specific LiteRT-LM runtime

## Product Position

In this app, skills are not an open-ended automation platform. They are
controlled capabilities that help the wellbeing assistant use local app state
without exposing raw private data.

Allowed first-party skill categories:

- health summary lookup
- mood and check-in lookup
- local memory retrieval
- privacy review and redaction explanation
- model status and model management guidance
- non-medical habit planning
- cloud upload preview using anonymized payloads only

Disallowed skill behavior:

- uploading raw health samples
- uploading raw chat or journal text
- reading contacts, precise location, medication, reproductive health, or
  medical records without a separate approved design
- executing arbitrary network calls from imported skills
- changing health data, deleting local data, or starting uploads without user
  confirmation
- bypassing `PrivacyFilterService`, `RiskBoundaryService`, or `LlmRuntime`

## Target Architecture

```text
presentation/chat
  -> AgentController
  -> AgentRuntime
  -> AgentPromptBuilder
  -> ToolRegistry
  -> first-party AgentTool implementations
  -> application services / repositories

AgentRuntime
  -> LlmRuntime only
```

The agent layer must not call Pigeon APIs, databases, HealthKit, Health
Connect, LiteRT-LM, Gemma, or cloud clients directly.

## Core Concepts

`AgentSkill`

Describes a skill that can be shown to the user and injected into the agent
prompt. A skill may enable one or more tools.

`AgentTool`

A typed Dart object that executes one bounded action. Tools call application
services, not platform APIs directly.

`AgentToolRegistry`

Owns the list of available and enabled tools. It resolves model-requested tool
calls to approved tool implementations.

`AgentRuntime`

Coordinates one user turn:

```text
1. Build safe prompt context.
2. Ask LlmRuntime for a response.
3. Parse tool calls if present.
4. Check policy and user confirmation.
5. Execute tools.
6. Feed sanitized tool results back to LlmRuntime.
7. Emit final answer and UI progress events.
```

`AgentTurnEvent`

Streaming event consumed by the chat UI. It can represent text, thinking,
tool progress, tool result summaries, warnings, and completion.

## Tool Policy

Every tool must declare:

- stable name
- user-visible description
- input schema
- output sensitivity
- whether user confirmation is required
- whether the result may be inserted into the model prompt

Tool results are sanitized before they are returned to the model. High and
restricted sensitivity results must be summarized or blocked.

## Initial Tool Set

Recommended first implementation:

```text
get_recent_health_summary
get_recent_mood_summary
search_local_wellbeing_memory
explain_privacy_redaction
preview_cloud_payload
get_model_status
suggest_non_medical_habit_plan
```

These are enough to build a useful local wellbeing coach without opening a
general-purpose automation surface.

## Gallery Mapping

| Gallery concept | Our equivalent |
| --- | --- |
| `AgentChatTask` | `AgentRuntime` + Flutter chat controller |
| `AgentTools` | first-party `AgentTool` implementations |
| `SkillManagerViewModel` | `AgentSkillRepository` / `ToolRegistry` |
| `loadSkill` tool | prompt builder selecting enabled skills |
| `runJs` tool | not enabled by default |
| `runIntent` tool | not enabled in Phase 1 |
| LiteRT-LM tool annotations | platform-specific runtime adapter detail |

## Implementation Order

1. Add domain contracts for skills, tools, calls, and results.
2. Add `AgentToolRegistry` and `AgentRuntime` interfaces.
3. Implement deterministic tool-call parsing tests.
4. Implement first-party health summary and model status tools.
5. Add prompt templates for tool calling.
6. Add privacy and safety tests for every tool.
7. Later, expose optional imported skills behind a review/approval system.

