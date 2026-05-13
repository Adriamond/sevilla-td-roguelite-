# Lifecycle Rules

These rules are mandatory for gameplay runtime ownership.

## Run lifecycle

- `GameplayRoot` persists for the whole run/map.
- `DefenseLayer` persists for the whole run.
- Placed defenses persist across rounds in the same run.
- Build pad occupancy persists across rounds in the same run.
- `RunState` resets per run.

## Wave lifecycle

- `EnemyLayer` resets per wave.
- Wave timers/state reset per wave.

## Screen transitions

- Room/Reward screens may overlay or hide gameplay.
- Room/Reward transitions must not destroy run-lifecycle objects.

## Ownership boundaries

- UI may request actions but must not own gameplay rules.
- `RunController` owns run progression.
- `WaveController` owns spawn scheduling and wave completion.
- `DefenseController` owns placement, build spending path, and defense lifecycle.

## Validation requirement

- Any feature that adds persistent runtime objects must include deterministic lifecycle smoke validation.

## MCP/editor inspection

- Godot AI MCP may inspect live scene state, hierarchy, node properties, logs, and screenshots when useful.
- MCP inspection must not change runtime lifecycle ownership rules.
- Room/Reward lifecycle, `GameplayRoot` persistence, and wave/run reset rules remain source-of-truth even when using editor automation.
- MCP write actions that affect scenes, scripts, resources, project settings, or saved state require explicit CR scope and must follow `docs/current_workflow.md`.
