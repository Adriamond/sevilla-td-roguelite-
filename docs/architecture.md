# Architecture

## Principle

Separate data, systems, scenes and UI.

The project must not rely on a monolithic manager.

## Layers

### Data layer

Located in:

* `scripts/defs/`
* `data/`

Responsibilities:

* define content contracts
* store tunable content
* expose stable ids

### Core layer

Located in:

* `scripts/core/`

Responsibilities:

* reusable pure logic
* weighted tables
* tag queries
* id validation
* metrics structures

### Gameplay layer

Located in:

* `scripts/gameplay/`

Responsibilities:

* run state
* waves
* spawning
* combat
* effects
* economy
* rewards
* room interactions
* boss logic

### UI layer

Located in:

* `scripts/ui/`
* `scenes/ui/`
* `scenes/menus/`

Responsibilities:

* display state
* receive input
* call high-level gameplay APIs
* never own gameplay rules

### Autoload layer

Located in:

* `autoload/`

Responsibilities:

* app state
* current run state
* content database
* RNG service
* save service
* audio service

Autoloads should stay small.

Autoload scripts are registered by singleton name in project.godot. Do not declare class_name in autoload scripts using the same name as the singleton key, because Godot 4.6 treats this as a parser conflict. Autoload scripts should be accessed through their configured singleton names: AppState, RunState, ContentDB, RNGService, SaveService and AudioService. Runtime gameplay should use these singleton names directly; standalone headless tools may instantiate service scripts manually when necessary.

## System ownership

| System                | Owns                    | Does not own               |
| --------------------- | ----------------------- | -------------------------- |
| RunController         | run state transitions   | combat, rewards, UI        |
| WaveController        | round schedule          | spawning internals, damage |
| SpawnController       | enemy instancing        | economy, reward            |
| DefenseController     | placement/upgrades/sell | targeting math internals   |
| TargetingService      | target selection        | effects, economy           |
| EffectSystem          | status effects          | wave scheduling            |
| EconomySystem         | gold and costs          | reward selection UI        |
| RewardSystem          | reward candidates       | card UI rendering          |
| RoomInteractionSystem | room effects            | room scene layout          |
| BossController        | boss phases             | generic enemy stats        |
| TelemetrySystem       | local metrics           | gameplay decisions         |

## Scene guidelines

Scenes should be thin.

A scene may:

* hold nodes
* connect signals
* call a system

A scene should not:

* contain balance values
* duplicate formulas
* decide reward logic
* own enemy scaling formulas

## Gameplay runtime lifecycle

For gameplay runs, runtime objects have distinct lifecycles:

* `GameplayRoot` is run-lifecycle and must persist for the whole run.
* `DefenseLayer`, placed defenses and build-pad occupancy are run-lifecycle.
* `EnemyLayer` is wave-lifecycle and may reset between waves.
* Room and reward views may overlay/hide gameplay, but must not destroy run-lifecycle objects.
* Any feature that creates persistent runtime objects must include lifecycle smoke validation.

## Data loading

`ContentDB` loads content Resources and indexes them by id.

It should validate:

* missing ids
* duplicate ids
* invalid references
* missing scene paths
* invalid category values
* invalid rarity values

## Paths

MVP uses fixed `Path2D`.

Do not implement dynamic pathfinding in MVP.

## Signals

Use signals to decouple:

* enemy reached end
* enemy died
* gold changed
* core hp changed
* wave started
* wave completed
* reward selected
* room interaction used

## Telemetry

Local telemetry should record:

* seed
* selected character
* selected map
* picked items
* defenses built
* damage by defense
* gold earned/spent
* leaks
* boss time-to-kill
* victory/defeat
* run duration
