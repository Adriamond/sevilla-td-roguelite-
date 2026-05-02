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
const ROUND_SEQUENCE: Array[String] = [
	"round_01",
	"round_02",
	"round_03",
	"round_04",
	"round_05",
	"round_06_boss"
]

func start_run(seed: int, character_id: String, map_id: String) -> void:
	_run_state().call("reset_run", seed, character_id, map_id)
	current_state = RunStateType.ROOM
	run_started.emit()
	state_changed.emit(current_state)

func continue_from_room() -> void:
	transition_to(RunStateType.BUILD_PHASE)

func enter_build_phase() -> void:
	transition_to(RunStateType.BUILD_PHASE)

func start_current_wave() -> void:
	transition_to(RunStateType.WAVE_RUNNING)

func handle_wave_completed() -> void:
	if bool(_run_state().call("is_defeated")):
		handle_core_depleted()
		return
	_run_state().call("add_gold", get_round_reward_gold())
	transition_to(RunStateType.REWARD_SELECTION)

func handle_core_depleted() -> void:
	end_run(false)

func accept_reward(item_id: String) -> void:
	if item_id.is_empty():
		return
	if _content_db().call("get_item", item_id) == null:
		return

	var run_state: Node = _run_state()
	var picked_item_ids: Array[String] = run_state.get("picked_item_ids")
	picked_item_ids.append(item_id)
	run_state.set("picked_item_ids", picked_item_ids)

	if is_final_round():
		end_run(true)
		return

	var next_round: int = int(run_state.get("current_round")) + 1
	run_state.set("current_round", next_round)
	run_state.get("round_changed").emit(next_round)
	transition_to(RunStateType.ROOM)

func get_current_round_id() -> String:
	var round_index: int = int(_run_state().get("current_round")) - 1
	if round_index < 0 or round_index >= ROUND_SEQUENCE.size():
		return ""
	return ROUND_SEQUENCE[round_index]

func get_current_round_def() -> Resource:
	var round_id: String = get_current_round_id()
	if round_id.is_empty():
		return null
	return _content_db().call("get_round", round_id)

func get_round_reward_gold() -> int:
	var current_round: int = int(_run_state().get("current_round"))
	return 45 + 15 * current_round

func is_final_round() -> bool:
	return int(_run_state().get("current_round")) >= ROUND_SEQUENCE.size()

func transition_to(new_state: RunStateType) -> void:
	current_state = new_state
	state_changed.emit(current_state)

func end_run(victory: bool) -> void:
	current_state = RunStateType.VICTORY if victory else RunStateType.DEFEAT
	run_ended.emit(victory)
	state_changed.emit(current_state)

func _run_state() -> Node:
	return get_node("/root/RunState")

func _content_db() -> Node:
	return get_node("/root/ContentDB")
