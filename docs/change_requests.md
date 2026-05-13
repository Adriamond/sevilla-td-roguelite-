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

---

## CR-009 - Basic defense selling

Status: implemented
Date: 2026-05-02

Requester intent:

Allow removing bad placements by selecting a placed `manguerazo` during Build Phase and selling it for a partial gold refund.

Affected areas:

- Design: MVP placement flexibility and faster balance iteration
- Code: defense selection/selling flow in gameplay layer + minimal debug UI wiring
- Data: no schema/id changes
- UI: selected-defense and sell controls in existing debug panel
- Balance: refund policy by round
- Docs: CR tracking update

Decision:

Implement a minimal sell loop for the single existing defense only, with refund policy in gameplay controller logic and sell disabled during running waves.

Implementation notes:

- Added clickable defense hit area in `defense_base.tscn` and click signal in `DefenseActor`.
- Extended `DefenseController` with:
  - selection tracking
  - pad-to-defense ownership release on sell
  - sell guards (`WaveController.is_running()`)
  - refund formula:
    - rounds 1-2: 80% of `base_cost`
    - round 3+: 70% of `base_cost`
- Added compact debug UI fields in gameplay panel:
  - selected defense id
  - sell refund amount
  - sell button
- Selling removes defense node, releases pad occupancy, and refunds gold through `RunState.add_gold`.
- Extended smoke validation with deterministic checks for:
  - build -> select -> sell
  - refund amount correctness
  - pad becomes buildable again
  - sell blocked during wave running

Files likely affected:

- `scripts/gameplay/defense_controller.gd`
- `scripts/gameplay/defense_actor.gd`
- `scenes/defenses/defense_base.tscn`
- `scripts/ui/gameplay_root_controller.gd`
- `scenes/gameplay/gameplay_root.tscn`
- `tools/validate_flow_smoke.gd`
- `tools/validate_project.gd`
- `docs/change_requests.md`

Risks:

- Selection UX is intentionally debug-minimal and may need polish when a full shop/interaction UI is added.

Acceptance criteria:

- Build phase defense can be selected and sold.
- Refund amount follows round policy.
- Selling releases occupied pad and allows rebuilding.
- Selling is blocked during wave running.
- Existing run/wave/reward flow remains intact.

---

## CR-009B - Refine sell refund rules and debug UI layout

Status: implemented
Date: 2026-05-02

Requester intent:

Make pre-wave selling fully refundable and keep debug controls reachable after CR-009 UI growth.

Affected areas:

- Design: clearer sell fairness and better debug usability
- Code: defense participation tracking and refund policy refinement
- Data: no schema/id changes
- UI: compact debug panel behavior
- Balance: sell refund tuning only
- Docs: CR tracking update

Decision:

Refund 100% for defenses that have not participated in any wave. After first wave participation, apply existing round-based refund formula. Keep controls visible by compacting the debug panel content.

Implementation notes:

- Added `has_participated_in_wave` flag to `DefenseActor`.
- `DefenseController` now:
  - marks active defenses as participated when a wave starts
  - refunds 100% if defense never participated
  - otherwise uses existing 80% (rounds 1-2) / 70% (round 3+) formula
- `GameplayRootController.start_wave()` now marks defenses participated once wave start is accepted.
- Compact debug panel adjustment:
  - hides low-priority viewport/camera/window rows at runtime
  - retains visibility of `Start Wave`, `[DEBUG] Force Complete`, and `Sell Selected` controls.
- Extended `validate_flow_smoke.gd` to verify:
  - pre-wave sell refunds 100%
  - post-wave sell in next build phase uses formula refund.

Files likely affected:

- `scripts/gameplay/defense_actor.gd`
- `scripts/gameplay/defense_controller.gd`
- `scripts/ui/gameplay_root_controller.gd`
- `scenes/gameplay/gameplay_root.tscn`
- `tools/validate_flow_smoke.gd`
- `docs/change_requests.md`

Risks:

- Minimal; participation is tracked as a single boolean and intentionally does not model detailed combat history.

Acceptance criteria:

- Selling before wave returns full build cost.
- Selling after participation uses round formula.
- Debug action/sell controls remain reachable.
- Existing run/wave/reward flow remains intact.

---

## CR-010 - Single upgrade level for manguerazo

Status: implemented
Date: 2026-05-02

Requester intent:

Allow the player to invest in an already placed `manguerazo` with one simple upgrade step during Build Phase.

Affected areas:

- Design: incremental progression on persistent defenses
- Code: defense level/upgrade state, upgrade economy, selected-defense UI controls
- Data: no schema/id changes
- UI: selected-defense panel now shows level and upgrade data
- Balance: one fixed upgrade cost and one fixed damage multiplier
- Docs: CR tracking update

Decision:

Implement exactly one upgrade level (`1 -> 2`) with fixed cost `45` and `+50%` damage, only during Build Phase. Keep all upgrade/refund calculations in gameplay layer.

Implementation notes:

- `DefenseActor` now tracks:
  - `level` (starts at 1, max 2)
  - `total_invested_cost`
  - one-shot upgrade method and upgrade cost getter
- Upgrade behavior:
  - cost: `45`
  - effect: `damage *= 1.5`
  - range/fire rate unchanged
- `DefenseController` now provides:
  - selected-upgrade eligibility checks
  - upgrade execution with `RunState.spend_gold()`
  - upgrade failure reasons
  - sell refund based on `total_invested_cost`:
    - never participated: 100%
    - participated rounds 1-2: 80%
    - participated round 3+: 70%
- `GameplayRootController` selected-defense UI now shows:
  - defense id
  - level
  - upgrade cost
  - sell refund
  - Upgrade button
  - Sell button
- Upgrade is disabled during wave running and at max level.
- Extended smoke validation to cover:
  - upgrade in build phase
  - max-level lockout
  - pre-wave full refund of upgraded investment
  - post-wave formula refund from total invested cost
  - upgrade persistence into next build phase
- Extended project validation with level/upgrade sanity checks for `DefenseActor`.

Files likely affected:

- `scripts/gameplay/defense_actor.gd`
- `scripts/gameplay/defense_controller.gd`
- `scripts/ui/gameplay_root_controller.gd`
- `scenes/gameplay/gameplay_root.tscn`
- `tools/validate_flow_smoke.gd`
- `tools/validate_project.gd`
- `docs/change_requests.md`

Risks:

- Upgrade UI is intentionally debug-minimal and may be replaced when a full shop panel is introduced.

Acceptance criteria:

- Selected `manguerazo` upgrades once during Build Phase.
- Upgrade cost/gold spend and max-level lockout behave correctly.
- Upgrade persists across round transitions in same run.
- Sell refund uses total invested cost with existing participation rules.
- Existing run/wave/reward flow remains intact.

---

## CR-010B - Verify upgrade stats and split gameplay debug UI panels

Status: implemented
Date: 2026-05-02

Requester intent:

Make upgrade impact explicitly visible/verified and prevent critical gameplay controls from being pushed off-screen by a growing single debug panel.

Affected areas:

- Design: debug UX clarity and panel responsibility split
- Code: selected-defense stat presentation and hit feedback
- Data: no schema/id changes
- UI: split debug layout into status/defense/actions panels
- Balance: no new upgrade levels; existing +50% single upgrade preserved
- Docs: CR tracking update

Decision:

Keep the one-level upgrade scope and reorganize gameplay debug UI into dedicated compact panels so `Start Wave` and `[DEBUG] Force Complete` remain visible, while exposing selected defense combat stats directly.

Implementation notes:

- Split gameplay debug UI into three panels:
  - run/wave status panel (top-left)
  - selected-defense panel (right side)
  - action/debug controls panel (bottom-left)
- Selected-defense panel now shows:
  - id
  - level
  - damage
  - range
  - fire rate
  - upgrade cost
  - sell refund
  - upgrade/sell buttons
- Added lightweight hit feedback to enemy actor via short-lived per-hit damage label (e.g. `-18.0`), improving in-wave upgrade effect readability.
- Extended flow smoke validation to assert exact upgrade damage formula:
  - level 2 damage == level 1 damage * 1.5
- Existing upgrade/sell/refund/persistence behavior remains intact.

Files likely affected:

- `scenes/gameplay/gameplay_root.tscn`
- `scripts/ui/gameplay_root_controller.gd`
- `scenes/enemies/enemy_base.tscn`
- `scripts/gameplay/enemy_actor.gd`
- `tools/validate_flow_smoke.gd`
- `docs/change_requests.md`

Risks:

- Debug panel layout remains placeholder-oriented and may be revised when a full gameplay HUD/shop is introduced.

Acceptance criteria:

- Upgrade stat increase is visible in selected-defense UI and validated in automated checks.
- Action controls remain visible and clickable in their own panel.
- Existing build/sell/upgrade/wave/reward flow remains working.

---

## CR-010C - Gameplay screen layout pass

Status: implemented
Date: 2026-05-03

Requester intent:

Reserve clear visual space for gameplay board versus debug/UI controls so core interactions remain readable as MVP controls grow.

Affected areas:

- Design: screen composition and reserved board area clarity
- Code: gameplay root board framing values only
- Data: no schema/id changes
- UI: runtime resolution and panel layout pass
- Balance: no combat/system changes
- Docs: CR tracking update

Decision:

Move to a 1280x720 debug runtime and split gameplay HUD into stable top/left/right regions, while reframing the map into a center board area.

Implementation notes:

- Updated runtime viewport to `1280x720`.
- Reworked `gameplay_root.tscn` into three stable UI zones:
  - top bar: phase, round, core HP, gold
  - left panel: Start Wave / Force Complete + active/spawned/leaked counters
  - right panel: selected defense stats/actions (level/damage/range/fire-rate/upgrade/sell)
- Added board framing constants in `GameplayRootController`:
  - map container offset into center play area
  - map container scale for board fit
  - camera centered for 1280x720 layout
- No gameplay logic changes to build/sell/upgrade/combat/wave/reward/defeat flow.

Files likely affected:

- `project.godot`
- `scenes/gameplay/gameplay_root.tscn`
- `scripts/ui/gameplay_root_controller.gd`
- `docs/change_requests.md`

Risks:

- Layout values are debug-MVP tuned and may need adjustment when final art HUD arrives.

Acceptance criteria:

- 1280x720 runtime readability.
- Board center area stays clear of side panels.
- Start Wave/Force Complete and selected-defense controls remain visible/reachable by phase.
- Existing gameplay flow remains intact.

---

## CR-011 - Add second basic defense cable_pelao

Status: implemented
Date: 2026-05-03

Requester intent:

Introduce a second basic build choice so early gameplay has meaningful placement/tuning decisions beyond a single defense.

Affected areas:

- Design: two-defense tactical choice in MVP
- Code: compact build-type selector and dual-defense validation coverage
- Data: tune/add `cable_pelao` DefenseDef values
- UI: left-panel build selector buttons
- Balance: basic stat profile differentiation only
- Docs: CR tracking update

Decision:

Keep one shared defense actor architecture and add `cable_pelao` as a second data-driven profile with distinct short-range/high-fire-rate behavior. Keep shop/elements/status out of scope.

Implementation notes:

- Tuned `data/defenses/cable_pelao.tres` profile:
  - lower damage
  - shorter range
  - faster fire rate
  - slightly lower cost
- Added compact build selector controls in gameplay left panel:
  - `Build Manguerazo`
  - `Build Cable Pelao`
  - selected build id display
- Pad clicks now build whichever defense id is currently selected.
- `DefenseActor` now applies a simple visual profile by defense id:
  - `manguerazo`: cyan water-like
  - `cable_pelao`: yellow electric-like
- Selling/selection/upgrade flows remain generic and work for both defenses.
- Extended validations:
  - `validate_project.gd` now initializes and sanity-checks `cable_pelao` setup.
  - `validate_flow_smoke.gd` now verifies build/select/sell for both defense ids, while preserving wave/reward lifecycle assertions.
- No status effects, elements, synergies, or shop UI were added.

Files likely affected:

- `data/defenses/cable_pelao.tres`
- `scenes/gameplay/gameplay_root.tscn`
- `scripts/ui/gameplay_root_controller.gd`
- `scripts/gameplay/defense_actor.gd`
- `tools/validate_project.gd`
- `tools/validate_flow_smoke.gd`
- `docs/change_requests.md`

Risks:

- Visual differentiation is debug-placeholder only and may be replaced by final art direction later.

Acceptance criteria:

- Both defense types are selectable/buildable and visually distinguishable.
- Both can be selected and sold.
- Wave/reward flow remains stable.
- No status/elements/synergies/shop scope added.

---

## CR-011B - Fix selected defense stats UI refresh

Status: implemented
Date: 2026-05-03

Requester intent:

Ensure the selected-defense panel always reflects the true currently selected defense and current stats when switching, upgrading, and selling.

Affected areas:

- Design: panel state consistency and reliability
- Code: selected-defense refresh source-of-truth handling
- Data: no schema/id changes
- UI: right-panel stat refresh behavior
- Balance: none
- Docs: CR tracking update

Decision:

Make selected-panel refresh state-driven from controller selection on every status refresh, rather than relying on potentially stale label values or one-off signal payloads.

Implementation notes:

- Added `_refresh_selected_defense_panel()` in `GameplayRootController`:
  - reads selected defense from `DefenseController.get_selected_defense()`
  - updates id/level/damage/range/fire-rate/upgrade-cost/sell-refund from live state
  - clears panel when no selection exists
- `_update_status_labels()` now always calls `_refresh_selected_defense_panel()`.
- `_on_defense_selected()` now delegates to `_refresh_selected_defense_panel()` for immediate consistency.
- `_on_defense_sold()` now clears via shared refresh path (through status refresh) and keeps clear state deterministic.
- Improved build hint message to use current selected build id (no stale hardcoded `manguerazo` text).
- Existing smoke already validates selection switching (`manguerazo` <-> `cable_pelao`) and upgraded-damage persistence on reselection.

Files likely affected:

- `scripts/ui/gameplay_root_controller.gd`
- `docs/change_requests.md`

Risks:

- Minimal; refresh frequency is small and tied to existing status updates.

Acceptance criteria:

- Selecting either defense updates right panel immediately.
- Upgrading selected defense updates level/damage panel immediately.
- Selling selected defense clears panel state.
- Switching away/back preserves upgraded stats display.

## CR-012 - First balance and readability pass for two-defense gameplay

Status: implemented
Date: 2026-05-03

Requester intent:

Tune early two-defense gameplay so rounds 1-3 are clearer and both `manguerazo` and `cable_pelao` feel useful without adding new systems.

Affected areas:

- Design: early readability and tactical identity clarity
- Code: none (data-only tuning)
- Data: defense/enemy/round numeric values for MVP early game
- UI: no structural changes
- Balance: first-pass tuning only
- Docs: CR tracking update

Decision:

Apply a conservative data-only balance pass to improve role separation and reduce early overwhelm risk while preserving current mechanics and lifecycle.

Implementation notes:

- Tuned defense profiles:
  - `manguerazo`: slightly higher cost/damage/range for steady medium-lane value.
  - `cable_pelao`: lower cost, shorter range, lower hit damage, faster fire rate for close-curve/choke use.
- Tuned early enemies for readability and pressure ramp:
  - reduced `tactichandal_runner` hp/speed.
  - slightly reduced `lagrima_negra` hp/speed.
- Tuned `round_02` pacing:
  - slower runner spawn interval.
  - fewer/slower `lagrima_negra` spawns.
- No new mechanics, defenses, enemies, schema changes, or map redesign.

Files likely affected:

- `data/defenses/manguerazo.tres`
- `data/defenses/cable_pelao.tres`
- `data/enemies/tactichandal_runner.tres`
- `data/enemies/lagrima_negra.tres`
- `data/rounds/round_02.tres`
- `docs/change_requests.md`

Risks:

- This is still a first-pass heuristic tune and may need further iteration after manual play batches.

Acceptance criteria:

- Validation suite passes.
- Early rounds feel more readable and less spikey.
- Both defenses keep distinct tactical identity and practical usefulness.
- Existing build/sell/upgrade/wave/reward flow remains intact.

## CR-013 - Add first real reward effects: litrito, media_bellota, rasta

Status: implemented
Date: 2026-05-03

Requester intent:

Make reward picks materially affect gameplay with three concrete MVP effects while keeping architecture simple.

Affected areas:

- Design: first meaningful roguelite reward impact
- Code: run-level reward resolution + defense stat usage
- Data: three new item resources
- UI: reward pool prioritization and effective range display
- Balance: early run modifiers and immediate economy/survival effects
- Docs: CR tracking update

Decision:

Implement a small ID-mapped reward resolution in gameplay layer (`RunController`) for `litrito`, `media_bellota`, and `rasta`, and apply resulting run modifiers to all defenses.

Implementation notes:

- Added item resources:
  - `litrito`: +10% global defense range multiplier and +10% global crit chance (capped at 50%).
  - `media_bellota`: immediate +30 gold.
  - `rasta`: immediate +10 core HP.
- Added run-level modifier state in `RunState`:
  - `defense_range_multiplier` (starts at `1.0`)
  - `global_crit_chance` (starts at `0.0`)
- Reward effects now apply in `RunController.accept_reward`.
- `DefenseActor` now uses run modifiers:
  - effective range recalculates from base range * run multiplier
  - attack rolls crit chance and applies `x2.0` damage on crit
- `EnemyActor.apply_damage` now accepts optional crit flag and displays `CRIT` in hit feedback text.
- Reward screen pool now prioritizes `litrito`, `media_bellota`, `rasta`.
- Extended flow smoke validation with deterministic checks for all three effects, crit cap, and effective range propagation.

Files likely affected:

- `autoload/run_state.gd`
- `scripts/gameplay/run_controller.gd`
- `scripts/gameplay/defense_actor.gd`
- `scripts/gameplay/enemy_actor.gd`
- `scripts/ui/gameplay_root_controller.gd`
- `scripts/ui/boot_controller.gd`
- `data/items/litrito.tres`
- `data/items/media_bellota.tres`
- `data/items/rasta.tres`
- `tools/validate_flow_smoke.gd`
- `docs/change_requests.md`

Risks:

- Reward resolution is intentionally ID-mapped for MVP speed and should evolve into a richer effect system later.

Acceptance criteria:

- Reward picks now produce meaningful gameplay effects.
- Effects apply through gameplay layer and persist for the run.
- Existing build/sell/upgrade/wave/reward flow remains stable.
- Validation suite remains passing.

## CR-014 - Fix per-defense upgrade, show round total and enable boss round

Status: implemented
Date: 2026-05-03

Requester intent:

Fix upgrade behavior across multiple same-type defenses, show round progress as current/total, and ensure the MVP final boss round is wired and visible.

Affected areas:

- Design: round progress clarity and final-round visibility
- Code: defense selection/upgrade UI state refresh, round-total propagation, boss spawn path robustness
- Data: boss enemy scene wiring
- UI: round label format and upgrade availability refresh on selection change
- Balance: no new systems, no new upgrade tiers
- Docs: CR tracking update

Decision:

Keep the existing MVP architecture and patch only the narrow failure points: per-selection upgrade button refresh, gameplay-layer total-round exposure, and boss round enemy actor wiring.

Implementation notes:

- Per-defense upgrade fix:
  - `GameplayRootController` now refreshes full status/button state on defense selection changes.
  - Added deterministic debug selection helper by id + match index for validation.
- Round total in HUD:
  - `RunState` now stores `total_rounds` for the active run.
  - `RunController.start_run` sets `total_rounds` from round sequence size.
  - HUD round value now renders as `current / total`.
- Boss round enablement:
  - `killo_bulevar_boss` now uses the active enemy actor scene so it actually spawns/moves/leaks/dies in wave flow.
  - Boss visual readability improved in `EnemyActor` (larger scale, boss label prefix, distinct color).
- Robustness hardening:
  - Added safe `/root/RunState` lookups in gameplay controllers during teardown edge cases.
- Validation updates:
  - Smoke now checks per-defense upgrade independence with two `manguerazo` instances.
  - Smoke verifies total rounds exposure and final round boss data resolution.
  - Project validation now sanity-checks boss enemy scene instantiation/setup.

Files likely affected:

- `autoload/run_state.gd`
- `scripts/gameplay/run_controller.gd`
- `scripts/ui/gameplay_root_controller.gd`
- `scripts/gameplay/defense_controller.gd`
- `scripts/gameplay/wave_controller.gd`
- `scripts/gameplay/enemy_actor.gd`
- `data/enemies/killo_bulevar_boss.tres`
- `tools/validate_flow_smoke.gd`
- `tools/validate_project.gd`
- `docs/change_requests.md`

Risks:

- Boss currently uses the shared enemy actor (intentional MVP scope). Dedicated boss mechanics remain future work.

Acceptance criteria:

- Per-defense upgrade works independently for same-type defenses.
- HUD shows round as `current / total`.
- Final round resolves boss round data and boss enemy spawns through wave system.
- Existing build/sell/upgrade/reward/defeat flow remains stable.

## CR-015 - Fix per-defense upgrade consistency and add kill gold rewards

Status: implemented
Date: 2026-05-03

Requester intent:

Stabilize per-selected-defense upgrade behavior and add basic kill-economy feedback so combat outcomes are readable and rewarding.

Affected areas:

- Design: clearer combat reward feedback and reliable build-phase upgrade interactions
- Code: enemy death payout path, controller/UI refresh reliability, validation coverage
- Data: no schema expansion required beyond existing `gold_reward` usage
- UI: immediate gold refresh + simple kill-gold feedback
- Balance: kill-gold now active from existing enemy data values
- Docs: CR tracking update

Decision:

Keep existing architecture and implement kill-gold in gameplay layer (`WaveController` on enemy death), while tightening selection-driven upgrade state updates and deterministic smoke checks.

Implementation notes:

- Per-defense upgrade consistency:
  - Upgrade enablement remains selection-driven via `DefenseController.can_upgrade_selected_defense()`.
  - Gameplay UI now refreshes status from selection changes and run-state gold changes to avoid stale button states.
- Kill gold rewards:
  - `EnemyActor` now carries `gold_reward` from `EnemyDef`.
  - `WaveController` listens for enemy `died` and awards gold through `RunState.add_gold()` exactly once.
  - Leaks continue through `reached_end` and do not grant kill gold.
- Visible feedback:
  - Final-hit feedback now shows `KO +<gold>g` on enemy hit label before removal.
  - HUD gold updates immediately via run-state signal refresh in gameplay UI.
- Validation:
  - Smoke now asserts two same-type defenses can both upgrade independently.
  - Smoke asserts kill-gold applies once per death and leak signals do not increase gold.
  - Content validation now enforces enemy `gold_reward >= 0`.

Files likely affected:

- `scripts/gameplay/enemy_actor.gd`
- `scripts/gameplay/wave_controller.gd`
- `scripts/ui/gameplay_root_controller.gd`
- `autoload/content_db.gd`
- `tools/validate_flow_smoke.gd`
- `docs/change_requests.md`

Risks:

- Kill feedback remains placeholder/debug style and may later move to a dedicated feedback layer.

Acceptance criteria:

- Upgrade availability remains correct per selected defense.
- Enemy kills grant gold exactly once per death.
- Leaks do not grant kill gold.
- Gold and kill feedback are visible during combat.
- Existing wave/reward lifecycle remains stable.

## CR-016 - Improve reward selection UI cards/readability

Status: implemented
Date: 2026-05-03

Requester intent:

Make reward selection understandable at a glance by replacing plain technical buttons with readable reward cards.

Affected areas:

- Design: reward presentation/readability
- Code: reward screen card text composition from item data
- Data: wording pass for existing reward item texts
- UI: card-style reward layout at 1280x720
- Balance: no reward mechanics changes
- Docs: CR tracking update

Decision:

Keep the same reward mechanics and selection flow, but upgrade the reward screen to three readable cards showing name, effect, flavor, and a small debug id.

Implementation notes:

- Reworked `reward_screen.tscn` into a full-screen card row (3 large buttons/cards).
- Updated `RewardScreenController` to render card text from `ContentDB` item data.
- Added explicit effect text rendering for current MVP rewards:
  - Litrito: +10% range, +10% crit chance
  - Media Bellota: +30 gold
  - Rasta: +10 Core HP
- Kept reward pick behavior unchanged (`reward_chosen(item_id)` path).
- Refined text fields in item data for clearer card copy.

Files likely affected:

- `scenes/ui/reward_screen.tscn`
- `scripts/ui/reward_screen_controller.gd`
- `data/items/litrito.tres`
- `data/items/media_bellota.tres`
- `data/items/rasta.tres`
- `docs/change_requests.md`

Risks:

- Placeholder visual style remains intentionally simple until final art/UI pass.

Acceptance criteria:

- Reward screen shows three readable cards.
- Cards clearly explain Litrito / Media Bellota / Rasta effects.
- Existing reward mechanics and flow remain unchanged.
- Validation suite remains passing.

## CR-A1 - Add map runtime contract validation

Status: implemented
Date: 2026-05-04

Requester intent:

Add deterministic headless validation for map runtime contracts before scaling from one MVP map to many maps.

Affected areas:

- Design: explicit runtime contract for map scenes
- Code: project validation contract checks for all `MapDef` scenes
- Data: no schema changes
- UI: none
- Balance: none
- Docs: CR tracking update

Decision:

Extend `validate_project.gd` with per-map runtime contract checks driven by `ContentDB.maps`, and keep the existing validation pipeline unchanged.

Implementation notes:

- `validate_project.gd` now loads `ContentDB` and validates every map resource scene contract:
  - map resource exists
  - `scene_path` exists and loads
  - scene instantiates and root is `Node2D`
  - `MainPath` exists with valid non-zero curve length
  - `ground_path_ids` includes `main` for current MVP runtime
  - path registration/retrieval for `main` succeeds
  - `StartMarker` and `EndMarker` exist
  - `BuildPads` exists with at least one pad
  - each pad exposes `pad_clicked` signal, script, stable id/name, non-empty `pad_category`
  - duplicate pad ids/names are rejected
  - `PathVisual` (if present) must have non-zero length
- Validation failures print explicit map-specific errors (e.g. `Map <id>: missing MainPath`).
- Existing enemy/defense/boss runtime checks now reuse one validated map scene from map contract pass.

Files likely affected:

- `tools/validate_project.gd`
- `docs/change_requests.md`

Risks:

- Current contract intentionally reflects MVP conventions (`MainPath`, markers, pad container) and should evolve in step with future multi-path map support.

Acceptance criteria:

- Validation runner includes map contract validation through `validate_project.gd`.
- Current Pino Montano map passes contract checks.
- Contract failures are explicit and map-specific.
- Existing gameplay behavior is unchanged.

## CR-A6 - Clean Godot shutdown leak warnings from validation runner

Status: implemented
Date: 2026-05-04

Requester intent:

Reduce or eliminate non-fatal shutdown leak warnings in headless validation scripts while keeping validation strict.

Affected areas:

- Design: validation reliability/readability
- Code: cleanup lifecycle in validation scripts
- Data: none
- UI: none
- Balance: none
- Docs: CR tracking update

Decision:

Refactor validation scripts to ensure deterministic teardown of instantiated nodes and enough frame draining before exit.

Implementation notes:

- `validate_project.gd` now runs in deferred async flow with centralized node tracking and cleanup on success/failure.
- Added consistent `_track_node()` and `_cleanup_created_nodes()` usage to avoid orphaned nodes/timers.
- `validate_flow_smoke.gd` now tracks temporary boot instances, waits additional frames, and drains pending timers before final quit.
- Validation behavior and assertions were preserved (no weakening).
- `validate_project.gd` no longer emits shutdown leak/resource warnings in verbose runs after cleanup hardening.
- Remaining warning source identified in `validate_flow_smoke.gd` verbose run:
  - `Leaked instance: SceneTreeTimer ...`
  - `Orphan StringName: timeout`
  This appears tied to async timer teardown at process shutdown after heavy wave/boot smoke orchestration. It is non-fatal (exit code 0) and does not change gameplay state.

Files likely affected:

- `tools/validate_project.gd`
- `tools/validate_flow_smoke.gd`
- `docs/change_requests.md`

Risks:

- A single non-fatal `SceneTreeTimer` shutdown warning may still appear from flow smoke teardown timing.

Acceptance criteria:

- Validation pipeline still passes.
- Cleanup behavior is stricter and minimizes shutdown leak warnings without hiding output.

## CR-017 - Boss and late-round balance pass

Status: implemented
Date: 2026-05-04

Requester intent:

Tune final-round boss balance so the boss remains a final threat but becomes beatable with reasonable upgraded defenses and at least one useful reward.

Affected areas:

- Design: final-round difficulty/readability
- Code: narrow validation sanity check only
- Data: boss stats and round 6 pacing
- UI: none
- Balance: final boss and late-round pressure only
- Docs: CR tracking update

Decision:

Reduce the boss from an effectively impossible HP/speed profile to a slower, still tanky final threat, and delay/reduce round 6 runner pressure so defenses get a meaningful boss damage window.

Implementation notes:

- `killo_bulevar_boss` tuned:
  - HP reduced from `1400` to `780`.
  - speed reduced from `0.85` to `0.38`.
  - leak damage increased from `5` to `6` to preserve final threat.
- `round_06_boss` runner add wave tuned:
  - runner count reduced from `6` to `4`.
  - spawn interval increased from `0.9` to `1.2`.
  - start delay increased from `10.0` to `14.0`.
- Project validation now asserts the boss remains tankier than `resonante_bruiser` and slow enough for current MVP path readability.

Risks:

- Final balance still needs manual playtesting because real tower coverage depends heavily on pad placement and reward choices.

Acceptance criteria:

- Boss appears clearly in round 6.
- Several upgraded defenses can reduce boss HP meaningfully and should be able to kill it with reasonable play.
- Poor setup can still fail due to boss leak damage and late runner pressure.
- Validation suite passes.

## CR-018 - Add minimal room hub interactions

Status: implemented
Date: 2026-05-04

Requester intent:

Give the room hub a small gameplay role between rounds with three one-use interactions that support the tower defense run without adding exploration or meta-progression.

Affected areas:

- Design: minimal room/hub utility layer
- Code: run-state tracking, room interaction resolution, room UI wiring
- Data: existing room interaction resources repurposed/tuned for CR-018
- UI: room screen interaction buttons/status
- Balance: small one-use run support effects
- Docs: CR tracking update

Decision:

Implement three run-limited room interactions through `RunController` and `RunState`, with UI only requesting interactions and rendering availability. Router uses the simpler next-wave crit bonus path.

Implementation notes:

- Added run-state tracking for `used_room_interaction_ids`.
- Added pending/current next-wave crit bonus state for router.
- `RunController.use_room_interaction()` owns gameplay effects:
  - `llamar_madre`: +5 Core HP.
  - `buscar_monedas_pantalon`: +25 gold.
  - `reiniciar_router`: +10% crit for the next wave only.
- `WaveController` activates pending room bonuses on wave start and clears current wave bonuses on wave completion/force-complete.
- Room screen now shows three interaction buttons/cards, status, and result text.
- Flow smoke validates interaction effects, duplicate-use prevention, router pending crit, and reset on new run.

Risks:

- Router is intentionally implemented as a simple temporary combat modifier instead of reward reroll UI.

Acceptance criteria:

- Room displays three interactions.
- Each interaction can be used once per run and then becomes unavailable.
- Continue still enters Build Phase.
- Used state persists across rounds and resets on new run.
- Validation suite passes.

## CR-V2 - Room hub visual blockout and asset pipeline baseline

Status: implemented
Date: 2026-05-04

Requester intent:

Make the room hub feel like part of the MVP fantasy by adding a readable bedroom blockout and establishing a simple asset pipeline baseline.

Affected areas:

- Design: room hub visual blockout
- Code: hotspot wiring in room screen controller
- Data: none
- UI: 1600x900 runtime baseline and room hub layout
- Balance: none
- Docs: asset pipeline and CR tracking

Decision:

Use Godot-generated placeholder primitives for the room hub and avoid importing external assets for this CR.

Implementation notes:

- Runtime viewport updated to `1600x900`.
- Room hub now includes wall/floor, bed, desk, monitor, router, chair/pants, phone/door, status panel, interaction panel, and Continue button.
- Existing interactions can be triggered from spatial hotspots:
  - phone/door: `llamar_madre`
  - pants/chair: `buscar_monedas_pantalon`
  - router: `reiniciar_router`
- Existing interaction cards remain as fallback controls.
- Used interactions disable both cards and hotspots.
- Added asset folders and licensing notes:
  - `assets/placeholder/`
  - `assets/room/`
  - `assets/ui/`
  - `assets/licenses/`
  - `docs/assets_pipeline.md`

Risks:

- This is a layout blockout only; final art direction, animation, and room exploration remain future scope.

Acceptance criteria:

- Runtime opens at a readable `1600x900`.
- Room hub visually reads as a bedroom blockout.
- Router, pants, and phone/door hotspots trigger the existing interactions.
- Continue still enters Build Phase.
- Existing validation suite passes.

## CR-V2B - Fix room hub framing and placeholder visual quality

Status: implemented
Date: 2026-05-04

Requester intent:

Improve the room hub presentation after the first blockout by fixing framing/composition and replacing low-quality-looking placeholder imagery with cleaner Godot-native shapes.

Affected areas:

- Design: room composition and readable bedroom silhouettes
- Code: hotspot visual state update only
- Data: none
- UI: room hub layout and hotspot clarity
- Balance: none
- Docs: CR tracking update

Decision:

Keep the current room interaction gameplay unchanged and improve the 1600x900 room scene using flat, coherent Godot-drawn placeholder geometry instead of raster assets.

Implementation notes:

- Reframed `room_hub.tscn` for a clearer 1600x900 composition with reserved UI corners and a central room play space.
- Rebuilt furniture/prop silhouettes with simple ColorRect layers: wall/floor, bed, desk/monitor, chair/pants, router, phone and door.
- Moved fallback interaction cards to the top-right and action/status panels to left-side safe zones so they do not cover key props.
- Added hotspot highlight frames for phone/door, pants and router.
- Used interactions now gray out both the hotspot button and its highlight frame.
- No gameplay effects, tower defense mechanics, rewards or room interaction rules changed.

Risks:

- This remains placeholder blockout art; final illustration, animation and richer room exploration are future scope.

Acceptance criteria:

- Room is better framed at `1600x900`.
- Props and hotspots remain visible and readable.
- Used interactions are visibly marked.
- Continue and fallback controls remain accessible.
- Validation suite passes.

## CR-V2C - Isolate room screen from gameplay HUD and clean room presentation

Status: implemented
Date: 2026-05-04

Requester intent:

Make the Room hub read as a standalone between-round screen instead of being visually mixed with gameplay/build HUD panels.

Affected areas:

- Design: screen-state clarity and room presentation isolation
- Code: gameplay presentation visibility API and boot routing usage
- Data: none
- UI: Room/Gameplay/Reward visual separation
- Balance: none
- Docs: CR tracking update

Decision:

Keep `GameplayRoot` alive for run lifecycle, but explicitly hide its gameplay presentation layer whenever Room or Reward overlays are shown.

Implementation notes:

- Added `GameplayRootController.set_gameplay_presentation_visible()` to hide/show both the gameplay root and its `CanvasLayer` HUD.
- Added `GameplayRootController.is_gameplay_presentation_visible()` for deterministic smoke validation.
- Updated `BootController._set_gameplay_visible()` to use the explicit presentation API instead of only setting the root node visibility.
- Extended flow smoke validation to assert:
  - gameplay runtime exists behind Room;
  - gameplay presentation is hidden in Room;
  - gameplay presentation is visible in Build Phase;
  - gameplay presentation hides again after Reward returns to Room;
  - gameplay presentation returns after Continue into the next Build Phase.
- No gameplay lifecycle, room effects, reward mechanics or tower-defense behavior changed.

Risks:

- This relies on the current `UILayer` CanvasLayer name in `gameplay_root.tscn`; future HUD restructuring should preserve or update the presentation API.

Acceptance criteria:

- Room displays without gameplay HUD panels.
- Gameplay runtime remains alive behind Room/Reward where required.
- Build/Wave presentation returns correctly after Continue.
- Validation suite passes.

## CR-V2C-FIX - Fit RoomHub cleanly inside 1600x900 viewport and remove clipping

Status: implemented
Date: 2026-05-04

Requester intent:

Fix RoomHub viewport fit after HUD isolation so the room renders fully inside the 1600x900 game window without right/bottom clipping or off-screen panels.

Affected areas:

- Design: RoomHub framing and viewport-safe composition
- Code: room controller viewport-fit helper and project validation bounds check
- Data: none
- UI: RoomHub screen fit only
- Balance: none
- Docs: CR tracking update

Decision:

Keep the existing room concept and interaction flow, but treat RoomHub as a designed `1600x900` canvas that scales and centers safely inside the actual viewport.

Implementation notes:

- Added `RoomScreenController.DESIGN_SIZE = 1600x900`.
- RoomHub now fits itself to the active viewport on ready, on show, and on viewport resize.
- Added `get_designed_content_rect()` for non-visual validation of fitted bounds.
- Added project window size overrides matching the 1600x900 viewport baseline.
- Extended `validate_project.gd` with a RoomHub viewport-fit check that instantiates the room, lets it fit, and asserts the designed content rect remains within viewport bounds.
- No room interaction effects, gameplay lifecycle, rewards, tower-defense mechanics or balance changed.

Risks:

- The validation checks bounds rather than screenshot composition; manual visual review is still required for taste/framing.

Acceptance criteria:

- RoomHub content fits inside the active viewport.
- Right interaction panel and Continue button remain visible.
- Gameplay HUD remains hidden in Room through the existing CR-V2C presentation visibility path.
- Validation suite passes.

## CR-V2C-FIX2 - Move RoomHub internal UI/content inside 1600x900 design canvas and validate actual node bounds

Status: implemented
Date: 2026-05-04

Requester intent:

Fix the actual RoomHub child-node layout after manual screenshots showed the previous canvas-fit validation could still pass while real panels/buttons were clipped.

Affected areas:

- Design: RoomHub internal composition and safe margins
- Code: room fit behavior and stricter project validation
- Data: none
- UI: RoomHub panel/hotspot placement only
- Balance: none
- Docs: CR tracking update

Decision:

Move the real RoomHub UI/content nodes into conservative safe bounds inside the `1600x900` design canvas, stop centering the canvas inside debug viewport chrome, and validate named node bounds directly.

Implementation notes:

- RoomHub fitting now anchors the design canvas at top-left and caps scale at `1.0` to avoid artificial grey margins or scaled-up clipping.
- Moved right-side interaction panel from the extreme right edge into a safer x range.
- Moved phone/door hotspot and door prop leftward to keep labels/buttons fully visible.
- Moved bottom action/message/Continue panel upward to keep the Continue button away from bottom clipping.
- Moved pants/chair hotspot upward for bottom safety.
- `validate_project.gd` now checks actual global rects for key RoomHub nodes:
  - `InteractionPanel`
  - `ActionPanel`
  - `ContinueButton`
  - `RoomMessageLabel`
  - status panel
  - all three hotspot buttons and frames
- Validation also enforces extra right/bottom safety margins for the previously clipped nodes.
- No room interaction effects, gameplay lifecycle, rewards, combat or balance changed.

Risks:

- Validation now catches geometric clipping risks, but final presentation quality still depends on manual screenshot review.

Acceptance criteria:

- Key RoomHub UI nodes are inside `1600x900` design bounds.
- Right panel and bottom Continue area use conservative safe margins.
- Validation suite passes.

## CR-WORKFLOW-MCP - Document Godot AI MCP usage rules for live-editor inspection and controlled scene automation

Status: implemented
Date: 2026-05-13

Requester intent:

Update the project workflow after CR-MCP-0 so Godot AI MCP can help with live editor inspection and scene/layout debugging without weakening small-CR discipline or allowing uncontrolled editor writes.

Affected areas:

- Design: workflow/process governance only
- Code: none
- Data: none
- UI: none
- Balance: none
- Docs: workflow, lifecycle, CR template, agent rules, CR tracking

Decision:

Document Godot AI MCP as an optional tool with explicit safety levels, read-only-first guidance, no-writes-while-playing rules, reporting requirements, and visual CR acceptance limits.

Implementation notes:

- `docs/current_workflow.md` now defines:
  - MCP role as supplemental to repo search, validation and manual testing.
  - native MCP tool mode vs direct JSON-RPC fallback.
  - CR-MCP-0 version mismatch caveat (`2.4.3` session metadata vs `3.2.4` initialize metadata).
  - Level 0 through Level 3 safety rules.
  - read-only-first policy for visual/layout CRs.
  - no MCP writes while the editor is playing.
  - `project_run` autosave caution.
  - per-CR MCP reporting requirements.
  - visual acceptance rule requiring validation plus manual/screenshot confirmation.
- `docs/next_cr_template.md` now includes MCP usage, screenshot, visual acceptance, and editor-state requirement fields.
- `docs/lifecycle_rules.md` notes that MCP inspection does not change lifecycle ownership rules.
- `AGENTS.md` points agents to the MCP workflow rules and summarizes high-risk MCP restrictions.
- No gameplay logic, scenes, scripts, validation scripts, project settings, resources, or addon files were changed for this CR.

Risks:

- MCP native tool availability may vary by Codex session; direct JSON-RPC remains documented as a fallback.

Acceptance criteria:

- Workflow docs explain Godot AI MCP role and limits.
- Native MCP vs direct JSON-RPC fallback is documented.
- No-writes-while-playing and `project_run` autosave cautions are documented.
- Future CR template includes MCP and visual screenshot fields.
- Small-CR workflow remains unchanged.
- Validation suite passes.

## CR-V2D - Clean gameplay Build/Wave layout to avoid panel overlap and improve 1600x900 readability

Status: implemented
Date: 2026-05-13

Requester intent:

Make the gameplay Build/Wave screen readable at the desktop MVP baseline after the RoomHub cleanup, using Godot AI MCP read-only inspection first.

Affected areas:

- Design: gameplay screen composition and safe layout zones
- Code: gameplay layout helper and project validation bounds checks
- Data: none
- UI: gameplay HUD/map/panel layout only
- Balance: none
- Docs: CR tracking update

Decision:

Keep gameplay mechanics unchanged and reframe the gameplay screen into explicit viewport-responsive zones: top status bar, left build/actions panel, central map playfield, and right selected-defense panel.

Implementation notes:

- Godot AI MCP direct JSON-RPC read-only inspection confirmed the editor was playing `res://scenes/gameplay/gameplay_root.tscn`.
- No MCP write actions were used because the editor was in playing state.
- `GameplayRootController` now calculates gameplay layout from the active viewport instead of old 1280-era fixed coordinates.
- The camera centers on the active gameplay viewport.
- The map playfield is sized and positioned between left/right panels without overlap, with a cap that avoids scaling placeholder map art above its design size.
- `validate_project.gd` now checks gameplay layout rects for top bar, side panels, map playfield, and key action buttons.
- No tower mechanics, wave logic, rewards, balance, RoomHub behavior, or content data changed.

Risks:

- Bounds validation catches overlap/clipping regressions, but final visual acceptance still requires manual Play/F5 screenshot review.

Acceptance criteria:

- Build/Wave gameplay zones do not overlap at the 1600x900 design baseline.
- Left build panel, right selected-defense panel, and top status bar stay inside the viewport.
- Map playfield remains large enough for desktop readability.
- Validation suite passes.

## CR-BIGMAP-1 - Add gameplay camera panning/zooming and map bounds clamping as preparation for larger maps

Status: implemented
Date: 2026-05-14

Requester intent:

Prepare the gameplay world for future larger maps by adding camera navigation infrastructure without changing current map size, path shape, gameplay balance, rewards, or room flow.

Affected areas:

- Design: world/HUD separation and navigation readiness
- Code: gameplay camera controls, map bounds API, deterministic camera validation
- Data: none
- UI: HUD remains fixed in `CanvasLayer`
- Balance: none
- Docs: CR tracking update

Decision:

Keep the existing small Pino Montano map intact, use its exposed map bounds for camera clamping, and add WASD pan plus mouse wheel zoom on the gameplay `Camera2D`.

Implementation notes:

- Godot AI MCP direct JSON-RPC read-only inspection confirmed the editor was playing `res://scenes/gameplay/gameplay_root.tscn`.
- No MCP write actions were used because the editor was in playing state.
- `PinoMontanoMap` now exposes `get_map_bounds()` based on the current background polygon, with a fallback route-derived bounds.
- `GameplayRootController` now:
  - makes `MainCamera` current on ready;
  - centers the camera on the loaded map bounds;
  - pans with WASD;
  - zooms with mouse wheel;
  - clamps zoom to the MVP debug range;
  - clamps camera position to map-derived world bounds with limited viewport padding for the current small map.
- HUD panels remain in `UILayer`/`CanvasLayer` and do not move or zoom with the world.
- `validate_project.gd` now checks map bounds availability and camera navigation sanity, including zoom clamping and camera clamp containment.
- No map enlargement, path corridor conversion, walls, minimap, reward changes, balance changes, or room-flow changes were made.

Risks:

- The current map is smaller than the 1600x900 viewport, so clamping intentionally allows only limited panning until CR-BIGMAP-2 enlarges the world footprint.
- Manual Play/F5 is still required to confirm input feel and click behavior after pan/zoom.

Acceptance criteria:

- WASD camera panning and mouse wheel zoom are implemented.
- Camera clamps to current map-derived world bounds.
- HUD remains fixed and readable.
- Build/select/sell/upgrade and wave flow are unchanged.
- Validation suite passes.

## CR-BIGMAP-2 - Expand Pino Montano into a larger navigable map blockout using existing camera/world infrastructure

Status: implemented
Date: 2026-05-14

Requester intent:

Make the current Pino Montano gameplay world substantially larger while preserving the existing single-path MVP mechanics, HUD lifecycle, camera navigation, build/select/sell/upgrade flow, room flow, rewards, and wave logic.

Affected areas:

- Design: large map footprint/blockout only
- Scene: Pino Montano map background, route, markers, path visual, and build pad placement
- Code: map fallback route/bounds and initial camera focus helper
- Validation: large-map bounds, path length, marker, pad, and PathVisual consistency checks
- Balance: none
- Docs: CR tracking update

Decision:

Use the existing `Path2D` centerline as the authoritative movement path, expand the placeholder map to a larger 3000x1450 world footprint, and rely on CR-BIGMAP-1 camera pan/zoom/clamp infrastructure to navigate it.

Implementation notes:

- Godot AI MCP direct JSON-RPC was attempted first, but this session returned MCP protocol/HTTP errors despite port 8000 being open; no MCP write actions were used.
- `pino_montano_map.tscn` now uses a much larger blockout background with simple district polygons, a longer `MainPath`, matching `PathVisual`, moved START/END markers, and 16 unique build pads placed near the route.
- `pino_montano_map_path.gd` fallback route points and fallback map bounds now match the large blockout footprint.
- `GameplayRootController` starts the camera near `StartMarker` when a map is loaded, then clamps using the existing map-bounds API.
- `validate_project.gd` now checks that map bounds and path length are large enough for this blockout, path endpoints/markers/pads are inside bounds, pad ids remain unique, and `PathVisual` remains aligned with `MainPath` length/endpoints.
- No path corridor conversion, walls, minimap, reward changes, tower changes, balance changes, RoomHub changes, or external addon adoption were made.

Risks:

- The larger path increases travel time; this CR intentionally avoids balance changes, so manual Play/F5 should confirm the pacing still feels acceptable before later wide-corridor or balance CRs.
- Visual acceptance still requires manual Play/F5 because deterministic validation checks contract geometry, not aesthetic composition.

Acceptance criteria:

- Map footprint is substantially larger and exposed through `get_map_bounds()`.
- Camera can navigate the larger map through existing camera controls.
- `MainPath`, `PathVisual`, START/END markers, and build pads are consistent and validated.
- Existing build/select/sell/upgrade and wave flow remain unchanged.
- Validation suite passes.

## CR-EXPERIMENT-BIGMAP-POLISH - Large-map corridor readability polish experiment

Status: implemented on experimental branch
Date: 2026-05-14

Requester intent:

Evaluate whether Codex can safely handle a larger controlled CR by improving the large Pino Montano map presentation without changing gameplay mechanics or treating large CRs as the normal workflow.

Affected areas:

- Scene: large Pino Montano map visual hierarchy only
- Validation: corridor visual contract checks
- Docs: CR tracking update
- Gameplay mechanics: none
- Balance: none

Decision:

Keep `MainPath` as the authoritative enemy movement centerline and add separate wide corridor visuals around it so the larger map reads more like a traversable board without introducing pathfinding, walls, or movement changes.

Implementation notes:

- Work was performed on `experiment/large-cr-test` only.
- Godot AI MCP read-only inspection was attempted first; port 8000 was reachable, but direct JSON-RPC initialize failed in this session, so no MCP write actions or editor saves were used.
- Added `CorridorShadowVisual` and `CorridorVisual` `Line2D` nodes that match `MainPath`/`PathVisual` points but render as a wide corridor under the centerline.
- Added simple background blockout zones plus clearer START/END zones to improve large-map readability.
- Raised build pad layer ordering so pads remain visually prominent above the corridor.
- `validate_project.gd` now requires `CorridorVisual`, checks its width is meaningful, and ensures its endpoints/length stay aligned with `MainPath`.
- No defenses, enemies, rewards, RoomHub behavior, balance, pathfinding, walls, minimap, or architecture rewrites were added.

Risks:

- This is an experimental larger CR and requires manual Play/F5 review before considering any merge.
- The corridor is visual only; future wall/path-zone gameplay will need a separate staged design.

Acceptance criteria:

- Wide corridor visual exists and remains aligned with the authoritative path.
- START/END areas and build pads remain readable.
- Existing map contract and gameplay validations pass.
- Manual Play/F5 is still required for acceptance.
