# MVP Specification

## Goal

Build a small playable tower defense roguelite MVP.

The MVP must prove:

1. the core loop works;
2. tower defense decisions are meaningful;
3. rewards modify the run;
4. the room/hub layer adds risk/reward without bloating the game;
5. the codebase can scale through data-driven content.

## MVP scope

### Included

* 1 map
* 1 character
* 4 enemies
* 1 boss
* 8 defenses
* 10 items
* 3 room interactions
* 6 rounds
* main menu
* pause menu
* HUD
* reward screen
* victory screen
* defeat screen
* local telemetry

### Excluded

* multiple maps
* multiple characters
* meta-progression
* achievements
* online features
* co-op
* dynamic pathfinding
* procedural maps
* localization
* voice acting
* full narrative system
* in-game editor

## Language and tone

The MVP must use Spanish/Sevillian player-facing text.

The tone is:

- local
- vulgar
- satirical
- barrio/costumbrista
- arcade
- readable

The code and data ids remain technical.

Example mappings:

| Technical id | Player-facing name |
|---|---|
| `manue_el_encerrado` | `Manué er Encerrado` |
| `pino_montano_bloques_bulevar` | `Pino Montano: bloques der bulevar` |
| `tactichandal_runner` | `Canijo del chándal táctico` |
| `lagrima_negra` | `Er Lágrima Negra` |
| `resonante_bruiser` | `Metallero Resonante` |
| `clan_loot_summoner` | `Otakillo del Loot` |
| `killo_bulevar_boss` | `Er Killo der Bulevar` |
| `ventilador_nube` | `Ventiladó de la caló` |
| `aspersor_azotea` | `Aspersó de azotea` |
| `letrero_luminoso` | `Letrero del bareto` |
| `altavoz_resonante` | `Altavó reventao` |
| `matojera_humo` | `Matojera de humo` |
| `manguerazo` | `Manguerazo der patio` |
| `cable_pelao` | `Cable pelao` |
| `reja_pinchos` | `Reja con mala leche` |

## Map

### `pino_montano_bloques_bulevar`

Fantasy:

A surreal pixel-art version of Pino Montano with blocks, benches, a boulevard, a small roundabout and a fixed enemy route.

Mechanical layout:

* fixed ground path using `Path2D`
* optional secondary path for boss or special enemies later
* build pads divided into:

  * air pads
  * ground pads
  * wall pads

MVP gimmick:

* visual-only bus crossing event
* it may briefly obscure part of the screen
* it must not block input or create unavoidable leaks in MVP

## Character

### `manue_el_encerrado`

Stats:

* start gold: 140
* core hp: 20
* free reroll: 1 per round during rounds 1-3

Active ability:

* `modo_focus`
* slows game time for 2.5 seconds
* cooldown to be tuned
* used as emergency reaction tool

Passive:

* first defense built each round costs 10% less

## Enemies

### `tactichandal_runner`

Role:

* fast rusher
* punishes lack of slow/control

Base stats:

* hp: 70
* speed: 1.45
* armor: 0
* leak damage: 1

Tags:

* ground
* fast
* rusher

Weakness:

* slow
* knockback
* early control

Resistance:

* weak single-hit traps if not supported

### `lagrima_negra`

Role:

* debuffer
* temporarily reduces nearby defense fire rate

Base stats:

* hp: 95
* speed: 0.95
* armor: 0
* leak damage: 1

Tags:

* ground
* debuffer
* aura

Weakness:

* burst
* armor break not required

Resistance:

* smoke/confusion effects are less effective

### `resonante_bruiser`

Role:

* tank
* introduces armor

Base stats:

* hp: 180
* speed: 0.75
* armor: 2
* leak damage: 2

Tags:

* ground
* tank
* armored

Weakness:

* armor break
* wet
* damage over time

Resistance:

* low-damage multi-hit

### `clan_loot_summoner`

Role:

* summoner
* creates small minions or decoys

Base stats:

* hp: 85
* speed: 1.05
* armor: 0
* leak damage: 1

Tags:

* ground
* summoner
* swarm

Weakness:

* area damage
* wall traps

Resistance:

* pure single-target targeting if minions distract

## Boss

### `killo_bulevar_boss`

Role:

* final boss for round 6
* combines rusher bursts, armor windows and summon phases

Base concept:

* phase 1: normal movement
* phase 2: summons minor enemies
* phase 3: short dash bursts

Initial target:

* boss should be killable in 60-90 seconds by a reasonable build

## Defenses

MVP defenses:

1. `ventilador_nube`
2. `aspersor_azotea`
3. `letrero_luminoso`
4. `altavoz_resonante`
5. `matojera_humo`
6. `manguerazo`
7. `cable_pelao`
8. `reja_pinchos`

Backlog:

* `peaje_vecinal`

## Items

MVP items:

1. `botellin_congelado`
2. `abanico_prestado`
3. `ticket_bus_urbano`
4. `silla_playa`
5. `ventilador_viejo`
6. `montadito_apretado`
7. `bizum_pendiente`
8. `mochila_reparto`
9. `moneda_carro`
10. `estampa_plastificada`

## Room interactions

MVP interactions:

1. `encender_ventilador`
2. `buscar_monedas_pantalon`
3. `reiniciar_router`

## Run structure

1. Start in room.
2. Optional room interaction.
3. Enter build phase.
4. Build, upgrade or sell defenses.
5. Start wave.
6. Wave resolves.
7. Receive round gold.
8. Choose 1 of 3 rewards.
9. Return to room.
10. Repeat until round 6.
11. Round 6 boss.
12. Victory or defeat.

## Run length target

* MVP target: 15-18 minutes
* Full game target later: 22-28 minutes
