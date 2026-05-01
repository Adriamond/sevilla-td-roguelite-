extends Node

class_name RunController

signal run_started
signal run_ended(victory: bool)
signal state_changed(new_state: RunStateType)

enum RunStateType {
    ROOM,
    BUILD_PHASE,
    WAVE_RUNNING,
    REWARD_SELECTION,
    VICTORY,
    DEFEAT
}

var current_state: RunStateType = RunStateType.ROOM

func start_run(seed: int, character_id: String, map_id: String) -> void:
    RunState.reset_run(seed, character_id, map_id)
    current_state = RunStateType.ROOM
    run_started.emit()
    state_changed.emit(current_state)

func transition_to(new_state: RunStateType) -> void:
    current_state = new_state
    state_changed.emit(current_state)

func end_run(victory: bool) -> void:
    current_state = RunStateType.VICTORY if victory else RunStateType.DEFEAT
    run_ended.emit(victory)
    state_changed.emit(current_state)
