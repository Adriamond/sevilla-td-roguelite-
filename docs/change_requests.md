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

---

## CR-005 - Extract run progression logic from UI and add flow smoke validation

Status: implemented
Date: 2026-05-02

Requester intent:

Move run progression ownership out of UI and add deterministic headless smoke validation for the MVP run flow.

Affected areas:

- Design: architecture ownership clarity (UI thinness)
- Code: run progression rules moved to gameplay layer
- Data: no new schema or content ids
- UI: `boot_controller` reduced to orchestration and screen routing
- Balance: no new gameplay scope; existing reward formula preserved
- Docs: CR/task tracking update

Decision:

Concentrate progression decisions in `RunController` (wave completion reward payout, reward acceptance progression, final-round victory, defeat handling, and round definition resolution) and add `validate_flow_smoke.gd` to validate the non-rendering flow path in CI/local checks.

Implementation notes:

- `RunController` now owns high-level run progression methods and round/reward policy.
- `boot_controller` now delegates progression decisions to `RunController`.
- Added headless flow smoke validation for:
  - start run into ROOM
  - ROOM -> BUILD_PHASE -> WAVE_RUNNING transitions
  - wave completion reward payout
  - REWARD_SELECTION entry
  - reward acceptance returning to ROOM and incrementing round
- No towers/combat/targeting/placement logic added.

Files likely affected:

- `scripts/gameplay/run_controller.gd`
- `scripts/ui/boot_controller.gd`
- `tools/validate_flow_smoke.gd`
- `tools/run_validation.ps1`
- `docs/change_requests.md`
- `docs/codex_tasks.md`

Risks:

- If UI assumes old direct mutations, flow could regress.
- Smoke test scope is intentionally narrow and does not replace full gameplay integration tests.

Acceptance criteria:

- Run progression logic is owned by gameplay layer instead of UI.
- Flow smoke validation passes headlessly.
- Existing content/project validations remain intact.
- No new gameplay scope (towers/combat) introduced.

---

## CR-006A - Runtime display size and enemy visibility debug pass

Status: implemented
Date: 2026-05-02

Requester intent:

Fix manual testing readability by enforcing a larger runtime view and making placeholder enemies clearly visible during wave flow.

Affected areas:

- Design: debug readability only
- Code: debug HUD instrumentation and enemy readability tuning
- Data: no schema changes, no new ids
- UI: gameplay debug panel additions for resolution and counters
- Balance: temporary readability-oriented visibility pacing only
- Docs: CR tracking update

Decision:

Apply a focused debug pass: set readable runtime viewport, expose runtime resolution/camera info, add spawned/active/leaked counters, and increase enemy on-screen readability without adding new gameplay systems.

Implementation notes:

- Updated `project.godot` debug viewport to `960x540`.
- Added gameplay debug labels for viewport size, camera zoom, and window size.
- Added debug counters for spawned, active, and leaked enemies.
- Added `enemy_spawned` signal in `WaveController` for deterministic spawned counting.
- Increased enemy placeholder size/contrast, added per-enemy short id label, and enforced high z-order above map.
- Reduced placeholder enemy movement speed scale for better manual visual tracking.
- No towers/combat/targeting/placement added.

Files likely affected:

- `project.godot`
- `scenes/gameplay/gameplay_root.tscn`
- `scripts/ui/gameplay_root_controller.gd`
- `scenes/enemies/enemy_base.tscn`
- `scripts/gameplay/enemy_actor.gd`
- `scripts/gameplay/wave_controller.gd`
- `docs/change_requests.md`

Risks:

- Debug-focused visibility values may differ from future final tuning.

Acceptance criteria:

- Runtime window is clearly readable for manual testing.
- Enemy visibility and layering are obvious during movement.
- Debug panel exposes resolution and enemy counters.
- Existing CR-005 flow and validations remain passing.
- No new gameplay scope (towers/combat) introduced.

---

## CR-006B - Fix enemy path positioning and movement visibility

Status: implemented
Date: 2026-05-02

Requester intent:

Fix enemy path-following bugs so enemies visibly spawn at START and move along the yellow route at an observable pace during manual testing.

Affected areas:

- Design: pre-defense gameplay readability stabilization
- Code: enemy path sampling/positioning robustness and spawn path guards
- Data: no schema/id changes
- UI: existing debug counters reused for verification
- Balance: debug-speed readability tuning only
- Docs: CR tracking update

Decision:

Harden movement against path-bake edge cases by switching enemy traversal to robust polyline sampling (with control-point fallback), keep coordinate conversion explicit through `Path2D.to_global`, and reject spawns with invalid paths.

Implementation notes:

- `EnemyActor` now builds sampled path points and computes polyline length explicitly.
- Movement now samples against that polyline, avoiding zero-length/invalid baked-path behavior.
- Enemy label now includes progress percentage for debug visibility.
- Spawn now validates path existence/curve shape before completing enemy setup.
- Added project validation check to instantiate map + enemy, verify path viability, and run a lightweight enemy movement step.
- This is a bugfix/readability stabilization before defense placement.
- No towers/combat/targeting/placement added.

Files likely affected:

- `scripts/gameplay/enemy_actor.gd`
- `scripts/gameplay/spawn_controller.gd`
- `tools/validate_project.gd`
- `docs/change_requests.md`

Risks:

- Debug speed constants may be retuned later when defense/combat systems are introduced.

Acceptance criteria:

- Enemies spawn at path start and move visibly along route.
- Active/spawned/leaked counters remain coherent during movement.
- Core HP still decreases on leak and wave flow reaches reward selection.
- Existing validations and CR-005 smoke flow remain passing.
- No new gameplay scope (towers/combat) introduced.

---

## CR-007 - Single basic defense placement and targeting

Status: implemented
Date: 2026-05-02

Requester intent:

Add the first playable tower-defense slice: click pads to place one basic defense, spend gold, target enemies, deal damage, and allow kills before leaks.

Affected areas:

- Design: first minimal combat-ready pre-shop gameplay slice
- Code: build pad interaction, defense placement, targeting, enemy damage/death, wave lifecycle compatibility
- Data: existing `manguerazo` DefenseDef only
- UI: gameplay debug HUD now includes gold/build hints
- Balance: debug-level first-pass tuning only
- Docs: CR/task tracking update

Decision:

Implement only one defense path (`manguerazo`) with pad-click placement and simple targeting (most progressed enemy in range), while explicitly deferring upgrades/selling/shop/elements/status/armor systems.

Implementation notes:

- Added clickable build pads on Pino Montano map (ground category).
- Added `DefenseController` runtime build flow with:
  - category compatibility check
  - pad occupancy check
  - `RunState.spend_gold()` spending
  - defense scene instantiation/configuration
- Added `DefenseActor` with basic stats from `DefenseDef`:
  - damage, range, fire rate, targeting mode
  - attacks enemies in range using cooldown
- Added minimal `BuildPad` script for click signal routing.
- Upgraded `TargetingService` to support most-progressed target selection.
- Updated `EnemyActor` with `current_hp`, `apply_damage`, `died`, `is_alive`, and progress getter.
- Wave lifecycle remains compatible: enemies removed by leak or death reduce active count and wave completes when active reaches zero after spawns end.
- Added project validation checks for defense actor init (`manguerazo`) and enemy kill via `apply_damage`.

Files likely affected:

- `scripts/gameplay/defense_controller.gd`
- `scripts/gameplay/defense_actor.gd`
- `scripts/gameplay/build_pad.gd`
- `scripts/gameplay/targeting_service.gd`
- `scripts/gameplay/enemy_actor.gd`
- `scripts/ui/gameplay_root_controller.gd`
- `scenes/gameplay/gameplay_root.tscn`
- `scenes/maps/pino_montano/pino_montano_map.tscn`
- `scenes/defenses/defense_base.tscn`
- `tools/validate_project.gd`
- `docs/change_requests.md`
- `docs/codex_tasks.md`

Risks:

- This is an MVP debug slice and may require tuning once multiple defenses/upgrade systems are added.

Acceptance criteria:

- Single defense (`manguerazo`) can be placed on click pads by spending gold.
- Defense attacks and can kill enemies before leak.
- Wave/reward flow remains intact.
- No upgrades, no selling, no full shop UI, no elements/synergies/status/armor logic introduced.

---

## CR-007B - Preserve run-lifecycle gameplay runtime and add minimal combat feedback

Status: implemented
Date: 2026-05-02

Requester intent:

Fix defense loss by preserving gameplay runtime for the whole run, and add minimal visual combat feedback for manual verification.

Affected areas:

- Design: runtime lifecycle stabilization before expanding defense mechanics
- Code: boot/gameplay lifecycle routing, defense persistence, combat debug feedback
- Data: no content schema/id changes
- UI: room/reward overlay behavior while gameplay runtime persists
- Balance: no scope expansion beyond single-defense MVP slice
- Docs: lifecycle governance and CR tracking update

Decision:

Treat `GameplayRoot`, `DefenseLayer` and pad occupancy as run-lifecycle state. Keep gameplay instance alive across build/wave/reward/room transitions during the same run. Add lightweight enemy health/hit feedback and defense shot beam for observability.

Implementation notes:

- `boot_controller` now keeps one gameplay runtime instance for the run and uses overlay screens for room/reward.
- Gameplay runtime is cleaned only on new run start/menu/victory/defeat cleanup.
- `GameplayRootController` exposes lifecycle helpers (`prepare_for_round`, `reset_run_runtime`, `end_wave_cleanup`) and keeps defense state across rounds.
- `DefenseController` occupancy now persists during run and resets only per run.
- Added enemy health bar + hit flash and defense short beam feedback.
- Extended flow smoke validation with lifecycle persistence checks:
  - build -> wave defense persistence
  - reward/room/next-build defense persistence in same run

Files likely affected:

- `scripts/ui/boot_controller.gd`
- `scripts/ui/gameplay_root_controller.gd`
- `scripts/gameplay/defense_controller.gd`
- `scripts/gameplay/enemy_actor.gd`
- `scripts/gameplay/defense_actor.gd`
- `scenes/enemies/enemy_base.tscn`
- `scenes/defenses/defense_base.tscn`
- `tools/validate_flow_smoke.gd`
- `docs/architecture.md`
- `AGENTS.md`
- `docs/change_requests.md`

Risks:

- Overlay layering may require later polish for full UX.
- Debug visuals are intentionally temporary and may need retuning once more defense systems are added.

Acceptance criteria:

- Build -> Wave keeps placed defense alive.
- Reward -> Room -> next Build keeps placed defense alive in same run.
- Minimal hit/shot feedback is visible.
- Existing run/reward flow and validations remain passing.
- No upgrades/selling/shop/elements/status/armor scope added.

---

## CR-007C - Fix gameplay phase UI state and build/wave flow robustness

Status: implemented
Date: 2026-05-02

Requester intent:

Prevent incoherent gameplay phase states (especially stale Wave Running UI with no active wave) and harden room/build/wave/reward transitions.

Affected areas:

- Design: phase-state consistency and anti-stuck runtime behavior
- Code: boot/gameplay phase guards, wave start guards, force-complete guards
- Data: no schema/id changes
- UI: explicit phase-aligned controls and build-pad interactivity
- Balance: no gameplay-scope expansion
- Docs: CR tracking update

Decision:

Make phase transitions state-driven and guarded: Wave Running can only be shown after a successful wave start. If wave start preconditions fail, recover to Build Phase and keep controls coherent.

Implementation notes:

- Added robust wave start checks (round data, path readiness, wave start success).
- Added gameplay phase reporting (`get_phase_name`) and boot-side recovery to Build Phase if start fails.
- Ensured Build Phase and Wave Running controls/buttons/pad interactivity are always coherent.
- Restricted Force Complete to active running waves only.
- Extended flow smoke validation with explicit phase assertions across:
  - room -> build
  - build -> wave
  - wave complete -> reward -> room -> next build
- Defense persistence and combat feedback remain intact.

Files likely affected:

- `scripts/ui/boot_controller.gd`
- `scripts/ui/gameplay_root_controller.gd`
- `scripts/gameplay/wave_controller.gd`
- `tools/validate_flow_smoke.gd`
- `docs/change_requests.md`

Risks:

- Minimal: stricter guards may surface existing latent setup errors sooner (desired for robustness).

Acceptance criteria:

- No dead Wave Running UI with zero wave activity before a valid wave start.
- Room -> Continue always yields Build Phase.
- Build/Wave controls and build-pad interactivity match phase.
- Reward -> Room -> Continue resets to Build Phase.
- Existing persistence and attack feedback remain functioning.

---

## CR-007D - Validation cleanup: investigate Godot shutdown leak warnings

Status: implemented
Date: 2026-05-02

Requester intent:

Eliminate or reduce non-fatal shutdown leak warnings in validation output by fixing real cleanup causes instead of suppressing logs.

Affected areas:

- Design: validation reliability/readability
- Code: flow smoke validation runtime behavior
- Data: no schema/id changes
- UI: none
- Balance: none
- Docs: CR tracking update

Decision:

Keep warnings visible and investigate root cause. Fix underlying source in validation path by preventing long-lived SceneTreeTimer awaits during headless smoke runs.

Implementation notes:

- Isolated warning source to `validate_flow_smoke.gd`.
- Verbose inspection showed leaked `SceneTreeTimer` plus `WaveStepDef` resources held by async wave-spawn await path during early quit.
- Added deterministic test-mode switch in `WaveController`:
  - `use_async_timers` (default `true` for normal gameplay)
  - smoke validation sets it to `false` to avoid timer-await leaks while preserving flow checks.
- Kept validation semantics intact and did not hide/suppress stderr output.
- Full `run_validation.ps1` output is now clean (no shutdown leak warnings).

Files likely affected:

- `scripts/gameplay/wave_controller.gd`
- `tools/validate_flow_smoke.gd`
- `docs/change_requests.md`

Risks:

- Minimal: test-only flag could be misused if toggled outside validation. Default behavior remains unchanged.

Acceptance criteria:

- Validation runner still passes all checks.
- Shutdown leak warnings removed from validation output.
- No gameplay behavior changes.

---

## CR-007E - Show Defeat screen on core depletion instead of closing game

Status: implemented
Date: 2026-05-02

Requester intent:

When Core HP reaches 0, transition to Defeat UI instead of closing the application window.

Affected areas:

- Design: defeat flow reliability
- Code: defeat transition guards and deterministic defeat smoke coverage
- Data: no schema/id changes
- UI: defeat screen routing and runtime teardown behavior
- Balance: none
- Docs: CR tracking update

Decision:

Keep quit behavior exclusive to Main Menu Quit action, and harden defeat transitions so core depletion can only end a run once and always routes to Defeat state/screen without app termination.

Implementation notes:

- Added run-finished guards in `RunController` to prevent duplicate `end_run`/state transitions after defeat or victory.
- Added one-shot core-depleted emission guard in `GameplayRootController` to avoid duplicate defeat triggering from repeated leaks.
- Extended `validate_flow_smoke.gd` with a deterministic defeat path:
  - start run
  - trigger core depletion transition
  - assert `RunController` enters `DEFEAT`
  - assert defeat screen controller is active and app tree remains alive
- No new gameplay systems were added.

Files likely affected:

- `scripts/gameplay/run_controller.gd`
- `scripts/ui/gameplay_root_controller.gd`
- `tools/validate_flow_smoke.gd`
- `docs/change_requests.md`

Risks:

- Minimal; tighter guards may surface hidden caller-order issues earlier, which is desirable.

Acceptance criteria:

- Core depletion shows Defeat screen and does not quit app.
- Main Menu Quit still exits the app.
- Validation suite remains passing.

---

## CR-008A - Add compact workflow and lifecycle docs

Status: implemented
Date: 2026-05-02

Requester intent:

Reduce future CR prompt size by centralizing repeated workflow, validation, lifecycle, and prompt-structure rules in stable docs.

Affected areas:

- Design: process clarity for future CR execution
- Code: none
- Data: none
- UI: none
- Balance: none
- Docs: new workflow/lifecycle/template docs and AGENTS references

Decision:

Add concise process docs that future prompts can reference directly instead of repeating long instructions.

Implementation notes:

- Added `docs/current_workflow.md` with CR sequencing, validation protocol, manual-test order, and handoff requirements.
- Added `docs/lifecycle_rules.md` with run/wave lifecycle boundaries and ownership rules.
- Added `docs/next_cr_template.md` with reusable compact CR prompt structure.
- Updated `AGENTS.md` to reference the new docs.

Files likely affected:

- `docs/current_workflow.md`
- `docs/lifecycle_rules.md`
- `docs/next_cr_template.md`
- `AGENTS.md`
- `docs/change_requests.md`

Risks:

- Minimal; documentation drift is possible if future process changes are not mirrored in these docs.

Acceptance criteria:

- New docs exist and are concise.
- AGENTS points to them.
- Future CR prompts can be shortened by referencing these docs.

---

## CR-008B - Map layout v2 and better build pad placement

Status: implemented
Date: 2026-05-02

Requester intent:

Improve the single-path Pino Montano placeholder map so first-defense placement has clearer tactical choices without expanding gameplay scope.

Affected areas:

- Design: map readability and tactical pad value distribution
- Code: path fallback constant alignment
- Data: no schema/id changes
- UI: none
- Balance: placement opportunity readability only
- Docs: CR tracking update

Decision:

Keep a single-path MVP and redesign route geometry plus pad positions to create stronger, medium, and situational placements while preserving current run/wave/combat systems.

Implementation notes:

- Updated `MainPath` and `PathVisual` route with a longer, more varied path and a near-parallel segment zone for stronger range overlap decisions.
- Kept START/END markers clearly visible with updated label positions.
- Repositioned pads and added one extra ground pad (`pad_05`) to improve practical placement choices:
  - at least two high-opportunity pads near multi-pass/turn geometry
  - at least two medium/situational pads
  - no pad overlapping the path or debug UI area
- Updated `scripts/gameplay/pino_montano_map_path.gd` fallback route points to match the new path layout.
- No gameplay systems, content ids, or schema were changed.

Files likely affected:

- `scenes/maps/pino_montano/pino_montano_map.tscn`
- `scripts/gameplay/pino_montano_map_path.gd`
- `docs/change_requests.md`

Risks:

- Pad strength remains heuristic for MVP; further tuning may be needed once additional defenses are introduced.

Acceptance criteria:

- Single-path map remains readable from START to END.
- Enemies follow updated route correctly.
- Build pads are visible/clickable and offer meaningful early placement choices for `manguerazo`.
- Existing wave/reward/persistence flow remains intact.

---

## CR-008B-FIX - Fix Godot editor parser error for WaveController global class

Status: implemented
Date: 2026-05-02

Requester intent:

Resolve editor parser failure (`Could not parse global class "WaveController"`) so project scripts open and run cleanly in Godot 4.6 editor, not only through validation runner.

Affected areas:

- Design: tooling/runtime stability
- Code: parser reliability in gameplay controller scripts
- Data: no schema/id changes
- UI: no feature scope changes
- Balance: none
- Docs: CR tracking update

Decision:

Apply minimal parser-hardening fixes: correct `WaveController` script parse issue and add direct script compile/instantiation validation for core global gameplay controllers.

Implementation notes:

- Fixed indentation/parser issue in `scripts/gameplay/wave_controller.gd` (`complete_wave` block).
- Normalized stray indentation in `scripts/ui/gameplay_root_controller.gd` on `wave_controller` onready binding.
- Extended `tools/validate_project.gd` with `_validate_global_controller_scripts()`:
  - loads and instantiates `spawn_controller.gd`
  - loads and instantiates `wave_controller.gd`
  - fails validation if either cannot be parsed/instantiated.
- No gameplay behavior, map layout, content ids, or schema changes.

Files likely affected:

- `scripts/gameplay/wave_controller.gd`
- `scripts/ui/gameplay_root_controller.gd`
- `tools/validate_project.gd`
- `docs/change_requests.md`

Risks:

- Minimal; validation now fails earlier for parser/global-script issues, which is intended.

Acceptance criteria:

- Editor no longer reports global class parse failure for `WaveController`.
- `gameplay_root_controller.gd` opens cleanly.
- Existing CR-008B map changes remain intact.
- Validation suite remains passing.
