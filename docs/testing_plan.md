# Testing Plan

## Test types

### Unit tests

Target pure logic:

* weighted table selection
* id validation
* tag queries
* enemy scaling formulas
* reward filtering
* stabilizer logic
* economy calculations

### Integration tests

Target connected gameplay flows:

* load ContentDB
* start run
* room → build → wave → reward → room
* spawn enemy wave
* boss round
* victory/defeat

### Golden runs

Use fixed seeds to compare:

* run duration
* leaks
* damage by defense
* gold earned/spent
* selected items
* victory/defeat
* boss time-to-kill

## Required golden seeds

Initial placeholder seeds:

* `seed_neutral_001`
* `seed_greedy_001`
* `seed_bad_rewards_001`
* `seed_control_001`
* `seed_raw_damage_001`

## Manual test checklist

Before marking MVP playable:

* game opens from main menu
* run starts
* room interactions are visible
* build phase works
* wave starts and ends
* rewards appear
* rewards apply effects
* boss appears
* victory works
* defeat works
* no crashes during a complete run
