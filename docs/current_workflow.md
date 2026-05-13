# Current Workflow

Use this workflow for all change requests (CRs).

## Working model

- Work one CR at a time.
- Keep each CR small and scoped.
- Do not start the next CR until the current one is validated, manually tested, and committed.

## Validation protocol

After implementation, Codex must run:

`powershell -ExecutionPolicy Bypass -File .\tools\run_validation.ps1`

Rules:

- If validation fails, fix issues using the exact validation output.
- Re-run validation until it passes.
- Report validation result in the final CR handoff.

## Manual test protocol

- User runs manual Godot test only after validation passes.
- Codex should provide a compact manual test checklist for the CR acceptance path.
- If manual test fails, open a follow-up CR or continue within the same CR if requested.
- Visual CRs require manual Play/F5 verification or screenshot evidence before acceptance.
- MCP/editor inspection can support diagnosis, but it does not replace user manual acceptance.

## Godot AI MCP protocol

Godot AI MCP is an optional live-editor inspection and controlled automation tool. It supplements the normal repo workflow; it never replaces repository search, small CR scope, validation, manual Play/F5 checks, or commit discipline.

Current supported integration modes:

- Native MCP tools, if Codex exposes `mcp__godot_ai__...` tools after Codex is restarted while Godot AI is running.
- Direct JSON-RPC to `http://127.0.0.1:8000/mcp`, if native tools are unavailable.

If MCP is unavailable, Codex must say so clearly and continue with normal file-based workflow only when the CR can be completed safely without live editor context.

CR-MCP-0 caveat:

- Session metadata reported Godot AI `2.4.3`, while MCP initialize reported `3.2.4`.
- This version mismatch did not block read-only calls, but should be treated as a non-blocking caveat if MCP behavior is odd.

Safety levels:

- Level 0 - No MCP: docs-only, pure text, simple script/content edits where editor context adds no value.
- Level 1 - Read-only MCP: allowed by default when useful, especially for visual/layout/debugging. No files, scenes, or resources changed.
- Level 2 - Scoped assisted edit: allowed only when the active CR explicitly involves scene/layout/node/UI changes. Codex must report every edited node/file/resource.
- Level 3 - High-risk editor actions: requires explicit CR scope and caution. Includes `scene_save`, `project_run`, project settings changes, `script_patch`, `batch_execute`, broad node reparent/rename/delete operations, and plugin reload.

Read-only-first policy:

- For visual/layout/scene-composition CRs, Codex should consider read-only MCP inspection before editing when MCP is available.
- Useful read-only checks include session/editor state, current scene, play state, scene tree hierarchy, key node properties, node bounds/anchors/margins, selected node, editor logs, and screenshot or screenshot metadata.

No writes while playing:

- If the Godot editor is in `playing` state, only read-only inspection is allowed.
- Scene/script/node write actions, `scene_save`, and project setting changes are not allowed while playing.
- Before any MCP write operation, Codex must confirm the editor is not playing.

Use MCP for:

- Visual layout issues.
- Clipped UI.
- Scene composition.
- Control anchors/margins.
- Node hierarchy/bounds.
- Signal/connection inspection.
- Runtime/editor state confusion.
- Visual claims that previously failed manual verification.
- Cases where file-only inspection produced false confidence.

Do not use MCP for:

- Documentation-only CRs.
- Pure balance changes.
- Simple data/content changes.
- Straightforward GDScript changes that do not need editor context.
- Broad speculative refactors.
- Unrelated cleanup.

MCP reporting requirements:

- MCP reachable: yes/no.
- Native tools or direct JSON-RPC.
- Editor play state.
- Scene inspected.
- Read-only actions used.
- Write actions used, if any.
- Files/scenes/resources changed.
- Whether anything was saved through the editor.
- Validation result.
- Whether manual user test/screenshot is still required.

Visual CR acceptance rule:

- MCP inspection is not acceptance.
- A visual CR is accepted only when `run_validation.ps1` passes, the user manual Play/F5 check passes, and screenshot/manual observation matches Codex's claim.
- Codex must not claim "fully visible", "fixed", or "clean" for visual issues unless backed by actual screenshot or manual verification.

High-risk runtime note:

- `project_run` has `autosave=true` by default. Use it deliberately and only when the CR permits runtime execution through MCP.

## Merge/commit protocol

- Commit/push only after:
  - validation passes, and
  - manual test acceptance is confirmed.
- Do not chain multiple unvalidated CRs in one commit.

## Codex handoff requirements

Each CR handoff should include:

- changed files list
- validation command executed
- validation outcome (pass/fail)
- known follow-ups or risks (if any)
