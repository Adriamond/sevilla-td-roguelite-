# AGENTS.md

Instructions for AI coding agents working on this repository.

This project is a Godot 4 2D pixel-art tower defense roguelite MVP set in Seville.
The current priority is a small, playable, maintainable MVP. Do not expand scope unless explicitly asked.

---

## Project goals

Build a clean MVP with:

- Godot 4 stable
- Typed GDScript
- Data-driven content using custom `.tres` Resources
- 1 playable map
- 1 playable character
- 4 enemy types
- 1 boss
- 8 defenses
- 10 items
- 3 room interactions
- 6 rounds
- Basic menu, HUD, reward screen, victory and defeat screens
- Local logs/telemetry for balancing

The project must remain easy to extend with new maps, characters, enemies, defenses, items and rounds.

---

## Non-goals for MVP

Do not implement:

- Multiple playable maps
- Multiple playable characters
- Permanent meta-progression
- Online features
- Local co-op
- Save-game progression beyond minimal settings if needed
- Achievement systems
- In-game content editor
- Dynamic pathfinding
- Procedural maps
- Voice acting
- Full localization
- Complex cutscenes
- Paid plugins
- Assets with unclear licensing

If scope and architecture conflict, reduce content. Do not reduce architecture quality.

---

## Runtime lifecycle rules

- `GameplayRoot` is run-lifecycle state and must persist for the whole run.
- `DefenseLayer`, placed defenses and pad occupancy persist across rounds within the same run.
- `EnemyLayer` is wave-lifecycle and may reset each wave.
- Room/reward screens may overlay or hide gameplay, but must not destroy run-lifecycle gameplay objects.
- Changes that add persistent runtime objects must include deterministic lifecycle smoke validation.

---

## Source of truth documents

Before implementing gameplay, read:

- `docs/mvp_spec.md`
- `docs/content_schema.md`
- `docs/balance_notes.md`
- `docs/third_party_assets.md`
- `docs/codex_tasks.md`

If these docs conflict with chat instructions, the latest explicit user instruction wins.
If docs conflict with each other, stop and report the conflict before implementing.

---

## Required folder structure

Use this structure unless explicitly changed:

```text
res://
  autoload/
    app_state.gd
    run_state.gd
    content_db.gd
    rng_service.gd
    save_service.gd
    audio_service.gd

  scenes/
    boot/
    menus/
    room/
    gameplay/
    maps/pino_montano/
    ui/
    enemies/
    defenses/
    bosses/

  scripts/
    core/
      event_bus.gd
      weighted_table.gd
      tag_query.gd

    gameplay/
      run_controller.gd
      wave_controller.gd
      spawn_controller.gd
      path_controller.gd
      defense_controller.gd
      targeting_service.gd
      effect_system.gd
      economy_system.gd
      reward_system.gd
      room_interaction_system.gd
      boss_controller.gd

    defs/
      enemy_def.gd
      defense_def.gd
      item_def.gd
      character_def.gd
      map_def.gd
      round_def.gd
      wave_step_def.gd

  data/
    enemies/
    defenses/
    items/
    characters/
    maps/
    rounds/
    loot_tables/

  assets/
    art/placeholders/
    art/ui/
    art/tiles/
    audio/music/
    audio/sfx/
    fonts/

  tests/
    unit/
    integration/
    golden_runs/

  docs/
    game_rules.md
    content_schema.md
    balance_notes.md
    third_party_assets.md
    codex_tasks.md
