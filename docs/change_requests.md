# Change Requests

This file tracks design and implementation changes requested after the initial MVP specification.

Each change request must include:

- CR id
- title
- status
- date
- requester intent
- affected areas
- decision
- implementation notes
- files likely affected
- risks
- acceptance criteria

## Status values

- proposed
- accepted
- implemented
- rejected
- superseded

## CR template

### CR-XXX — Title

Status:
Date:
Requester intent:

Affected areas:

- Design:
- Code:
- Data:
- UI:
- Balance:
- Docs:

Decision:

Implementation notes:

Files likely affected:

Risks:

Acceptance criteria:

---

## CR-001 — Spanish/Sevillian player-facing language

Status: accepted
Date: 2026-05-01

Requester intent:

The game must not feel like a neutral Spanish tower defense. It must sound Sevillian, barrio, vulgar, local and satirical in all player-facing text.

Affected areas:

- Design: tone, naming, humor, flavor text
- Code: localization/text lookup support later
- Data: display names, descriptions, item/enemy/defense text
- UI: labels, messages, reward cards
- Balance: no direct impact
- Docs: tone guide and content schema

Decision:

Keep internal code technical and clean. Use Spanish/Sevillian slang only for player-facing content.

Implementation notes:

- Do not rename core classes or systems.
- Do not rename existing technical folders.
- Content ids remain stable lowercase snake_case.
- Add `display_name_es`, `description_es` or equivalent player-facing text fields where useful.
- Prefer a localization/text database approach before hardcoding UI text.
- All future content must include Spanish/Sevillian visible text.
- Humor should be vulgar and satirical but not hateful.

Files likely affected:

- `docs/tone_guide.md`
- `docs/content_schema.md`
- `docs/mvp_spec.md`
- `docs/agent_workflow.md`
- `agents.md`
- `README.md`
- future data resources under `data/`
- future localization files if added

Risks:

- Slang can reduce clarity.
- Excessive vulgarity can make UI noisy.
- Hardcoding text into UI scripts would make later editing painful.
- Offensive content could cross from satire into cruelty.

Acceptance criteria:

- Documentation clearly states that player-facing text is Spanish/Sevillian.
- Code naming remains clean and technical.
- Future content schema supports player-facing Spanish text.
- Agents know how to process future change requests.

Related docs:

- `docs/tone_guide.md`
- `docs/content_schema.md`
- `docs/agent_workflow.md`

---

## CR-002 — MVP data resources and ContentDB validation

Status: accepted
Date: 2026-05-02

Requester intent:

Implement Phase 1 data contracts properly with loadable MVP `.tres` resources and strict ContentDB validation, without implementing gameplay.

Affected areas:

- Design: no direct change
- Code: `ContentDB.load_all()` and `ContentDB.validate_all()`
- Data: MVP resource set under `data/`
- UI: no direct change
- Balance: placeholder values aligned with MVP notes
- Docs: CR tracking update

Decision:

Implement recursive `.tres` loading for all MVP content categories, index by stable ids, and enforce schema/reference sanity checks. Add a headless validation entrypoint.

Implementation notes:

- Keep architecture split and avoid monolithic gameplay manager logic.
- Keep technical ids stable and lowercase snake_case.
- Validate duplicate ids, missing required text fields, scene references, cross-resource references, and numeric sanity.
- Add exactly MVP-locked resources for enemies, defenses, items, character, map, room interactions, status effects, and rounds.

Files likely affected:

- `autoload/content_db.gd`
- `tools/validate_content.gd`
- `data/enemies/*.tres`
- `data/defenses/*.tres`
- `data/items/*.tres`
- `data/characters/*.tres`
- `data/maps/*.tres`
- `data/rounds/*.tres`
- `data/room_interactions/*.tres`
- `data/status_effects/*.tres`

Risks:

- Resource text format mistakes can break loading.
- Placeholder values may require later balancing.
- Overly strict validation may block future drafts if schema evolves.

Acceptance criteria:

- All MVP `.tres` resources exist.
- `ContentDB.load_all()` loads all MVP resources.
- `ContentDB.validate_all()` reports no errors on current MVP set.
- Duplicate ids are detected.
- Missing enemy references in rounds are detected.
- `tools/validate_content.gd` reports success/failure in headless mode.

---

## CR-003 — Minimal run state machine and placeholder navigation

Status: implemented
Date: 2026-05-02

Requester intent:

Deliver Phase 2 as a minimal playable navigation loop using placeholder screens and transitions, without implementing combat, spawning, defenses, or other gameplay systems yet.

Affected areas:

- Design: placeholder run loop UX
- Code: run state transitions and scene wiring
- Data: read-only use of existing MVP content ids
- UI: menu/room/build/wave/reward/victory/defeat placeholder navigation
- Balance: placeholder round reward application
- Docs: CR tracking and phase status update

Decision:

Use existing `RunController` and `RunState` to drive state transitions, keep UI thin, and keep gameplay logic out of scene scripts.

Implementation notes:

- Boot opens main menu.
- Start Run initializes debug seed, character, map and enters ROOM.
- ROOM -> BUILD_PHASE -> WAVE_RUNNING -> REWARD_SELECTION -> ROOM loop is implemented.
- Reward selection appends chosen item id to `RunState.picked_item_ids` and increments round.
- After round 6 reward resolution, flow transitions to VICTORY.
- DEFEAT placeholder scene remains available for future core_hp-based flow.
- CR-003 stabilization: fixed Godot warnings and verified CR-003 script parse readiness.

Files likely affected:

- `scripts/gameplay/run_controller.gd`
- `scripts/ui/*`
- `scenes/boot/boot.tscn`
- `scenes/menus/main_menu.tscn`
- `scenes/room/room_hub.tscn`
- `scenes/gameplay/gameplay_root.tscn`
- `scenes/ui/reward_screen.tscn`
- `scenes/ui/victory_screen.tscn`
- `scenes/ui/defeat_screen.tscn`
- `docs/codex_tasks.md`

Risks:

- Placeholder navigation can drift from final architecture if extended carelessly.
- UI-only placeholders may be mistaken for production flow if not documented.

Acceptance criteria:

- Main Menu can start a run.
- User can navigate Main Menu -> Room -> Build -> Dummy Wave -> Reward -> Room.
- Round increments after reward choice.
- Round 6 completion reaches Victory.
- No enemy/spawn/defense/combat gameplay implemented.

---

## CR-004 — Placeholder map, path movement, wave spawning and leak damage

Status: implemented
Date: 2026-05-02

Requester intent:

Replace dummy-wave flow with first real MVP wave loop: map load, fixed path movement, round-based spawning, leak damage, and wave completion into rewards.

Affected areas:

- Design: placeholder map readability and flow continuity
- Code: wave/spawn/path gameplay systems and gameplay scene integration
- Data: existing RoundDef/EnemyDef content consumption only
- UI: gameplay placeholder controls/status updates
- Balance: round reward payout preserved
- Docs: CR tracking and Phase 3 status note

Decision:

Implement a minimal real wave loop with fixed `Path2D` and leak handling, while explicitly excluding defenses, targeting, and combat.

Implementation notes:

- Added/updated placeholder map scene with `MainPath` `Path2D` and simple route visuals.
- Enemy placeholder now moves along assigned path and emits reach-end/removal signals.
- `WaveController` schedules `wave_steps` spawns via intervals and start delays.
- `SpawnController` instantiates enemies from `EnemyDef.scene_path` and assigns the main path.
- Leak at path end calls `RunState.damage_core(leak_damage)`.
- Wave completes when all planned spawns are done and active enemies are resolved.
- Core HP <= 0 transitions to Defeat; otherwise wave completion transitions to Reward Selection via existing flow.
- No tower placement, targeting, damage combat, or enemy attacks were added.

Files likely affected:

- `scenes/maps/pino_montano/pino_montano_map.tscn`
- `scenes/enemies/enemy_base.tscn`
- `scenes/gameplay/gameplay_root.tscn`
- `scripts/gameplay/path_controller.gd`
- `scripts/gameplay/spawn_controller.gd`
- `scripts/gameplay/wave_controller.gd`
- `scripts/gameplay/enemy_actor.gd`
- `scripts/ui/gameplay_root_controller.gd`
- `scripts/ui/boot_controller.gd`
- `tools/validate_project.gd`

Risks:

- Placeholder movement speed may need tuning for readability.
- Async spawn timing may need tightening under low frame rates.

Acceptance criteria:

- Start Run reaches gameplay wave flow from Room.
- Start Wave spawns enemies from `RoundDef.wave_steps`.
- Enemies move visibly along fixed path.
- Enemies leaking reduce core HP.
- Wave completion transitions to Reward Selection.
- Reward selection returns to Room and increments round.
- Core HP depletion transitions to Defeat.
- No tower/combat systems implemented.

---

## CR-004B — Readability pass for placeholder gameplay wave

Status: implemented
Date: 2026-05-02

Requester intent:

Improve manual readability/testability of the CR-004 placeholder wave without expanding gameplay scope.

Affected areas:

- Design: placeholder visual clarity
- Code: minor debug readability pacing and UI status display
- Data: round pacing tweak for observation
- UI: compact gameplay panel and non-obstructive layout
- Balance: temporary readability-oriented pacing for manual testing
- Docs: CR tracking update

Decision:

Apply a readability-focused pass only: larger test window, compact overlay, high-contrast map/path/enemy visuals, and slower observable wave pacing. No new gameplay systems.

Implementation notes:

- Increased gameplay window readability (`960x540`) with preserved stretch behavior.
- Gameplay HUD panel made smaller and kept out of path-critical area.
- Gameplay panel now shows only phase, round, core HP, active enemies, start wave, and debug force-complete.
- Map visuals updated to darker background with clearer high-contrast route and START/END markers.
- Enemy placeholder made larger with strong contrast and simple outline.
- Enemy runtime movement reduced via local debug speed scale.
- Round 1 spawn interval increased for easier visual confirmation.
- No towers/defenses/targeting/combat/final art added.

Files likely affected:

- `project.godot`
- `scenes/gameplay/gameplay_root.tscn`
- `scripts/ui/gameplay_root_controller.gd`
- `scenes/maps/pino_montano/pino_montano_map.tscn`
- `scenes/enemies/enemy_base.tscn`
- `scripts/gameplay/enemy_actor.gd`
- `data/rounds/round_01.tres`

Risks:

- Readability tuning may diverge from final balancing targets.
- Large debug window settings may differ from eventual shipping defaults.

Acceptance criteria:

- Gameplay area is easier to inspect manually.
- UI no longer blocks most of the path.
- Path/start/end/enemies are clearly visible.
- Active enemies counter changes visibly during wave.
- Leak damage and wave-complete-to-reward flow remain intact.
- No new gameplay scope introduced.

---

## CR-004C — Gameplay viewport fit, map framing and debug UI readability

Status: implemented
Date: 2026-05-02

Requester intent:

Ensure placeholder gameplay occupies the visible debug viewport comfortably, with full path visibility and non-obstructive compact debug UI.

Affected areas:

- Design: gameplay framing/readability
- Code: gameplay root presentation/framing updates
- Data: no schema/id changes
- UI: compact debug overlay positioning
- Balance: no gameplay-scope expansion
- Docs: CR tracking update

Decision:

Keep placeholder/debug scope and improve only framing and readability: stable viewport fit, deterministic camera framing, path margins, compact panel.

Implementation notes:

- Gameplay root converted to `Node2D` host with fixed `Camera2D` framing.
- Map occupies most of 960x540 view with safe margins and full route visibility.
- Path redraw uses wider high-contrast route across a meaningful screen area.
- START/END markers and labels remain fully visible.
- Debug panel reduced and kept in top-left margin with semi-transparent dark background.
- Debug panel shows only phase, round, core HP, active enemies, start wave, and optional force-complete debug action.
- No towers/defenses/targeting/combat/final art added.

Files likely affected:

- `project.godot`
- `scenes/gameplay/gameplay_root.tscn`
- `scripts/ui/gameplay_root_controller.gd`
- `scenes/maps/pino_montano/pino_montano_map.tscn`

Risks:

- Debug viewport/framing settings may differ from future shipping presentation.

Acceptance criteria:

- Gameplay map occupies most of visible window.
- Full path from START to END is visible and not clipped.
- UI does not cover main route.
- Enemy movement/leaks/reward transition flow remains intact.
- No new gameplay scope introduced.
