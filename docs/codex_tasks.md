# Codex Tasks

Use this as the implementation roadmap.

## Phase 0 - Repository bootstrap

Status: current task.

Deliverables:

* folder structure
* docs
* Resource definition stubs
* autoload stubs
* core utility stubs
* gameplay system stubs
* UI controller stubs

No gameplay implementation yet.

## Phase 0.1 - Language and change-request setup

Implement CR-001.

Deliverables:

- `docs/change_requests.md`
- `docs/tone_guide.md`
- `docs/agent_workflow.md`
- updated `AGENTS.md`
- updated `README.md`
- updated content schema
- Spanish/Sevillian text fields added to relevant Resource definition scripts

Acceptance:

- player-facing language direction is documented
- future changes have a CR workflow
- internal code naming remains technical
- no gameplay is implemented in this phase

## Phase 1 - Data contracts

Implement:

* Resource classes
* basic validation
* stable id rules
* placeholder sample content resources

Acceptance:

* ContentDB can load and validate data folders
* duplicate ids are detected
* missing references are detected

## Phase 2 - Run state machine

Status: implemented (CR-003 minimal placeholder navigation).

Implement states:

* BOOT
* MAIN_MENU
* ROOM
* BUILD_PHASE
* WAVE_RUNNING
* REWARD_SELECTION
* VICTORY
* DEFEAT
* PAUSED

Acceptance:

* transitions work with placeholder UI
* run can move room -> build -> wave -> reward -> room

## Phase 3 - Map and spawning

Implement:

* Pino Montano placeholder map
* fixed Path2D
* build pads
* wave spawning
* enemy movement
* leak damage

Acceptance:

* enemies follow path
* enemies damage core when reaching end
* wave ends correctly

## Phase 4 - Defenses and combat

Implement:

* placement
* targeting
* damage
* upgrades
* selling
* status effects

Acceptance:

* defenses kill enemies
* gold is spent/refunded correctly
* status effects work

## Phase 5 - Rewards and room interactions

Implement:

* reward screen
* 1 of 3 item choice
* reward stabilizer logic
* room interactions

Acceptance:

* selected rewards modify gameplay
* room interactions apply their benefits and risks

## Phase 6 - Boss and end states

Implement:

* boss round
* boss phases
* victory
* defeat
* run summary

Acceptance:

* round 6 ends in victory if boss dies
* player loses if core hp reaches 0

## Phase 7 - Testing and balance instrumentation

Implement:

* unit tests
* integration tests
* golden seeds
* local telemetry export

Acceptance:

* tests can be run headless or through documented workflow
* metrics are recorded after runs
