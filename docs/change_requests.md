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
