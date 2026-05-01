# AGENTS.md

Instructions for AI coding agents working on this repository.

This project is a Godot 4 2D pixel-art tower defense roguelite MVP set in Seville.

The current priority is a small, playable, maintainable MVP. Do not expand scope unless explicitly asked.

---

## Project goals

Build a clean MVP with:

- Godot 4 stable
- typed GDScript
- data-driven content using custom `.tres` Resources
- 1 playable map
- 1 playable character
- 4 enemy types
- 1 boss
- 8 defenses
- 10 items
- 3 room interactions
- 6 rounds
- basic menu, HUD, reward screen, victory and defeat screens
- local logs/telemetry for balance

The project must remain easy to extend with new maps, characters, enemies, defenses, items and rounds.

---

## Non-goals for MVP

Do not implement:

- multiple playable maps
- multiple playable characters
- permanent meta-progression
- online features
- local co-op
- save-game progression beyond minimal settings if needed
- achievement systems
- in-game content editor
- dynamic pathfinding
- procedural maps
- voice acting
- full localization
- complex cutscenes
- paid plugins
- assets with unclear licensing

If scope and architecture conflict, reduce content. Do not reduce architecture quality.

---

## Source of truth documents

Before implementing gameplay, read:

- `docs/mvp_spec.md`
- `docs/game_rules.md`
- `docs/content_schema.md`
- `docs/architecture.md`
- `docs/balance_notes.md`
- `docs/third_party_assets.md`
- `docs/codex_tasks.md`

If these docs conflict with chat instructions, the latest explicit user instruction wins.

If docs conflict with each other, stop and report the conflict before implementing.

---

## Required folder structure

Use the existing repository structure. Do not introduce parallel structures such as `src/`, `game/`, or `managers/` unless explicitly asked.

Important folders:

- `autoload/`: global app/run services only
- `scripts/core/`: pure reusable utilities
- `scripts/defs/`: Resource definitions
- `scripts/gameplay/`: gameplay systems
- `scripts/ui/`: UI controllers only
- `data/`: content resources
- `scenes/`: Godot scenes
- `docs/`: design and architecture docs
- `tests/`: unit, integration and golden run tests
- `tools/`: editor/dev validation utilities

---

## Architecture rules

Do not create a monolithic `GameManager`.

Use separated systems:

- `RunController`: run state transitions only
- `WaveController`: reads `RoundDef` and schedules wave steps
- `SpawnController`: spawns enemies and assigns paths
- `DefenseController`: placement, selling, upgrading and pad validation
- `TargetingService`: targeting logic only
- `EffectSystem`: status effects
- `EconomySystem`: gold, costs, bounties, sell values
- `RewardSystem`: reward generation, filtering and stabilizer logic
- `RoomInteractionSystem`: room choices and run modifiers
- `BossController`: boss-specific behavior
- `ContentDB`: load and validate content definitions

UI must not contain gameplay logic.

Scenes must not contain hardcoded balance values when those values belong in data resources.

Content must be referenced by stable string ids.

Autoload scripts are registered by singleton name in project.godot. Do not declare class_name in autoload scripts using the same name as the singleton key, because Godot 4.6 treats this as a parser conflict. Autoload scripts should be accessed through their configured singleton names: AppState, RunState, ContentDB, RNGService, SaveService and AudioService. Runtime gameplay should use these singleton names directly; standalone headless tools may instantiate service scripts manually when necessary.

---

## Data-driven content rules

Use custom Godot `Resource` classes for:

- `EnemyDef`
- `DefenseDef`
- `ItemDef`
- `CharacterDef`
- `MapDef`
- `RoundDef`
- `WaveStepDef`
- `RoomInteractionDef`
- `StatusEffectDef`

All content ids must be stable, lowercase snake_case strings.

Adding a new enemy, defense, item or round should usually require adding a new `.tres` Resource and possibly a scene, not rewriting core systems.

---

## Language and tone

All player-facing text must be Spanish with Sevillian/barriero tone.

Follow:

- `docs/tone_guide.md`

Internal code remains technical and mostly English.

Do not put slang into:

- class names
- file names
- system names
- folder names
- core architecture terms

Player-facing text may use vulgar Sevillian slang, but it must remain readable and must not become real-world hate.

Gameplay-critical text should state the mechanic clearly first, then add flavor.

Example:

Good:
"Ralentiza enemigos un 30% durante 2s. Los deja empanaos."

Bad:
"Yokeje illo, se quean to tiesos por la fuma."

If unsure, prioritize clarity.

---

## Change request handling

When a user asks for a change that affects design, gameplay, content, architecture, balance, UI or tone:

1. Add or update an entry in `docs/change_requests.md`.
2. Update source-of-truth docs before implementing.
3. List affected files.
4. Keep changes minimal.
5. Do not expand MVP scope silently.

---

## MVP content lock

For MVP, use exactly:

### Map

- `pino_montano_bloques_bulevar`

### Character

- `manue_el_encerrado`

### Enemies

- `tactichandal_runner`
- `lagrima_negra`
- `resonante_bruiser`
- `clan_loot_summoner`

### Boss

- `killo_bulevar_boss`

### Defenses

Use these 8 defenses:

- `ventilador_nube`
- `aspersor_azotea`
- `letrero_luminoso`
- `altavoz_resonante`
- `matojera_humo`
- `manguerazo`
- `cable_pelao`
- `reja_pinchos`

Do not implement `peaje_vecinal` in MVP unless explicitly requested.

### Items

- `botellin_congelado`
- `abanico_prestado`
- `ticket_bus_urbano`
- `silla_playa`
- `ventilador_viejo`
- `montadito_apretado`
- `bizum_pendiente`
- `mochila_reparto`
- `moneda_carro`
- `estampa_plastificada`

### Room interactions

- `encender_ventilador`
- `buscar_monedas_pantalon`
- `reiniciar_router`

---

## Coding style

- Use typed GDScript where practical.
- Prefer small scripts with single responsibility.
- Prefer clear names over clever abstractions.
- Use signals/events for decoupling when useful.
- Avoid global state except in approved autoload services.
- Avoid hidden dependencies on node order.
- Avoid magic numbers in gameplay systems.
- Put tunable values in Resources or constants documented in `docs/balance_notes.md`.
- Do not duplicate formulas.
- Do not introduce third-party plugins without documenting why.

---

## Testing requirements

When changing gameplay logic, add or update tests where possible.

Required test areas:

- content loading
- duplicate id validation
- missing reference validation
- weighted tables
- enemy scaling formulas
- reward filtering
- reward stabilizer logic
- run state transitions
- room interaction effects
- golden seed simulation

Before finishing a task, run the relevant test command if available.

If tests cannot be run, state why.

---

## Balance rules

Initial values:

```text
core_hp = 20
start_gold = 140
reward_options = 3
room_charges = 2
sell_value_rounds_1_2 = 0.8
sell_value_after_round_2 = 0.7
round_reward_gold = 45 + 15 * round_index
```

Scaling:

```text
enemy_hp = base_hp * (1 + 0.18 * (round - 1))
enemy_speed = base_speed * (1 + 0.03 * max(0, round - 3))
elite_hp = hp * 2.2
boss_hp = hp * 9.0
defense_upgrade_cost = base_cost * [1.0, 1.6, 2.2][level]
defense_damage = base_damage * (1 + 0.45 * level)
```
