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
var _run_finished: bool = false
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
	_run_finished = false
	current_state = RunStateType.ROOM
	run_started.emit()
	state_changed.emit(current_state)

func continue_from_room() -> void:
	transition_to(RunStateType.BUILD_PHASE)

func enter_build_phase() -> void:
	transition_to(RunStateType.BUILD_PHASE)

func start_current_wave() -> void:
	if _run_finished:
		return
	transition_to(RunStateType.WAVE_RUNNING)

func handle_wave_completed() -> void:
	if _run_finished:
		return
	if bool(_run_state().call("is_defeated")):
		handle_core_depleted()
		return
	_run_state().call("add_gold", get_round_reward_gold())
	transition_to(RunStateType.REWARD_SELECTION)

func handle_core_depleted() -> void:
	if _run_finished:
		return
	end_run(false)

func accept_reward(item_id: String) -> void:
	if _run_finished:
		return
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
	if _run_finished and new_state != RunStateType.VICTORY and new_state != RunStateType.DEFEAT:
		return
	current_state = new_state
	state_changed.emit(current_state)

func end_run(victory: bool) -> void:
	if _run_finished:
		return
	_run_finished = true
	current_state = RunStateType.VICTORY if victory else RunStateType.DEFEAT
	run_ended.emit(victory)
	state_changed.emit(current_state)

func _run_state() -> Node:
	return get_node("/root/RunState")

func _content_db() -> Node:
	return get_node("/root/ContentDB")
