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
const ROOM_INTERACTION_IDS: Array[String] = [
	"llamar_madre",
	"buscar_monedas_pantalon",
	"reiniciar_router"
]

func start_run(seed: int, character_id: String, map_id: String) -> void:
	_run_state().call("reset_run", seed, character_id, map_id)
	_run_state().set("total_rounds", ROUND_SEQUENCE.size())
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
	_apply_reward_effect(item_id, run_state)

	if is_final_round():
		end_run(true)
		return

	var next_round: int = int(run_state.get("current_round")) + 1
	run_state.set("current_round", next_round)
	run_state.get("round_changed").emit(next_round)
	transition_to(RunStateType.ROOM)

func use_room_interaction(interaction_id: String) -> Dictionary:
	var run_state: Node = _run_state()
	if interaction_id.is_empty() or not ROOM_INTERACTION_IDS.has(interaction_id):
		return {"ok": false, "message": "Interaccion no disponible."}
	if bool(run_state.call("has_used_room_interaction", interaction_id)):
		return {"ok": false, "message": "Ya lo has usado en esta run."}

	var interaction_def: Resource = _content_db().get("room_interactions").get(interaction_id)
	if interaction_def == null:
		return {"ok": false, "message": "Falta la data de la interaccion."}

	match interaction_id:
		"llamar_madre":
			run_state.call("heal_core", 5)
		"buscar_monedas_pantalon":
			run_state.call("add_gold", 25)
		"reiniciar_router":
			run_state.call("grant_next_wave_crit_bonus", 0.10)
		_:
			return {"ok": false, "message": "Interaccion sin efecto MVP."}

	run_state.call("mark_room_interaction_used", interaction_id)
	return {
		"ok": true,
		"message": String(interaction_def.get("success_text_es"))
	}

func get_room_interaction_view_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var run_state: Node = _run_state()
	var interactions: Dictionary = _content_db().get("room_interactions")
	for interaction_id: String in ROOM_INTERACTION_IDS:
		var interaction_def: Resource = interactions.get(interaction_id)
		if interaction_def == null:
			continue
		result.append({
			"id": interaction_id,
			"name": String(interaction_def.get("display_name_es")),
			"effect": _get_room_interaction_effect_text(interaction_id),
			"used": bool(run_state.call("has_used_room_interaction", interaction_id))
		})
	return result

func _get_room_interaction_effect_text(interaction_id: String) -> String:
	match interaction_id:
		"llamar_madre":
			return "+5 Core HP"
		"buscar_monedas_pantalon":
			return "+25 gold"
		"reiniciar_router":
			return "+10% crit en la proxima oleada"
		_:
			return "Efecto MVP"

func _apply_reward_effect(item_id: String, run_state: Node) -> void:
	match item_id:
		"litrito":
			var current_range_multiplier: float = float(run_state.get("defense_range_multiplier"))
			var current_crit_chance: float = float(run_state.get("global_crit_chance"))
			run_state.set("defense_range_multiplier", current_range_multiplier + 0.10)
			run_state.set("global_crit_chance", min(0.5, current_crit_chance + 0.10))
		"media_bellota":
			run_state.call("add_gold", 30)
		"rasta":
			run_state.call("heal_core", 10)

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

func get_total_rounds() -> int:
	return ROUND_SEQUENCE.size()

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
