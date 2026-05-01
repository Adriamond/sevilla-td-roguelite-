# Agent Workflow

This project is expected to receive iterative design changes.

Agents must treat user requests as change requests when they affect:

- gameplay
- tone
- content
- architecture
- balance
- UI
- scope
- data schema
- testing
- assets

## Workflow

1. Identify whether the request is:
   - design change
   - implementation task
   - bug fix
   - refactor
   - content addition
   - balance tuning
   - documentation update
2. If it changes product direction, add or update an entry in `docs/change_requests.md`.
3. Update affected source-of-truth docs before code when the change affects architecture or game rules.
4. Keep implementation minimal.
5. Do not expand scope silently.
6. Preserve stable technical ids unless the user explicitly approves a migration.
7. Keep internal code clean and technical.
8. Keep player-facing text Spanish/Sevillian.

## Prompt handoff format

When receiving a request, agents should structure their work as:

```text
Task:
Context:
Affected files:
Constraints:
Implementation steps:
Acceptance criteria:
Out of scope:
```

## Example

Task:
Apply CR-001 Spanish/Sevillian player-facing tone.

Context:
The repo already exists. Player-facing text must use Spanish/Sevillian slang, while internal code remains technical.

Affected files:

- docs/change_requests.md
- docs/tone_guide.md
- docs/content_schema.md
- docs/mvp_spec.md
- AGENTS.md

Constraints:

- Do not implement gameplay yet.
- Do not rename technical folders.
- Do not hardcode UI text into gameplay systems.

Acceptance criteria:

- Docs define tone rules.
- Schema supports player-facing Spanish text.
- AGENTS.md tells future agents to follow the tone guide.
