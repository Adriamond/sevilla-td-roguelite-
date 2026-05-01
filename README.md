# Sevilla TD Roguelite

Working title: **Killo Defense**.

A small Godot 4 MVP for a 2D pixel-art tower defense roguelite set in Seville.

The project is intentionally scoped small:

- 1 map
- 1 playable character
- 4 enemy types
- 1 boss
- 8 defenses
- 10 items
- 3 room interactions
- 6 rounds
- data-driven content
- local telemetry for balance
- web/desktop export target

## Stack

- Engine: Godot 4 stable
- Language: typed GDScript
- Content format: custom Godot Resources (`.tres`)
- Telemetry/logs: JSON or CSV
- Target platforms: web + desktop

## Current phase

Repository bootstrap.

No full gameplay should be implemented until the architecture and docs are in place.

## Language direction

The game is player-facing in Spanish with a Sevillian/barriero tone.

Internal code remains clean and technical, mostly English.

See:

- `docs/tone_guide.md`
- `docs/change_requests.md`
- `docs/agent_workflow.md`

## MVP content lock

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

- `ventilador_nube`
- `aspersor_azotea`
- `letrero_luminoso`
- `altavoz_resonante`
- `matojera_humo`
- `manguerazo`
- `cable_pelao`
- `reja_pinchos`

`peaje_vecinal` is backlog, not MVP.

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

## Key docs

Read these before implementing gameplay:

- `AGENTS.md`
- `docs/mvp_spec.md`
- `docs/content_schema.md`
- `docs/architecture.md`
- `docs/balance_notes.md`
- `docs/codex_tasks.md`
