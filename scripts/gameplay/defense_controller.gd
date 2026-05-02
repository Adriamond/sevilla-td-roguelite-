extends Node

class_name DefenseController

signal defense_built(defense_id: String)
signal build_failed(reason: String)
signal defense_selected(defense: DefenseActor, refund_amount: int)
signal defense_sold(defense_id: String, refund_amount: int)

var _defense_parent: Node2D = null
var _wave_controller: WaveController = null
var _occupied_pads: Dictionary = {}
var _defense_to_pad: Dictionary = {}
var _selected_defense: DefenseActor = null

func configure(defense_parent: Node2D, wave_controller: WaveController) -> void:
	_defense_parent = defense_parent
	_wave_controller = wave_controller

func can_build(defense_id: String, pad: Node2D, pad_category: String) -> bool:
	if _defense_parent == null or _wave_controller == null:
		return false
	if pad == null or not is_instance_valid(pad):
		return false
	if _occupied_pads.has(pad.get_instance_id()):
		var existing_defense: Node = _occupied_pads[pad.get_instance_id()]
		if existing_defense != null and is_instance_valid(existing_defense):
			return false
		_occupied_pads.erase(pad.get_instance_id())

	var defense_def: Resource = _content_db().call("get_defense", defense_id)
	if defense_def == null:
		return false
	if not _is_category_compatible(defense_def, pad_category):
		return false

	var run_state: Node = _run_state()
	return int(run_state.get("gold")) >= int(defense_def.get("base_cost"))

func build_defense(defense_id: String, pad: Node2D, pad_category: String) -> bool:
	if not can_build(defense_id, pad, pad_category):
		build_failed.emit("cannot_build")
		return false

	var defense_def: Resource = _content_db().call("get_defense", defense_id)
	var build_cost: int = int(defense_def.get("base_cost"))
	if not _run_state().call("spend_gold", build_cost):
		build_failed.emit("not_enough_gold")
		return false

	var defense_scene: PackedScene = load(String(defense_def.get("scene_path")))
	if defense_scene == null:
		build_failed.emit("missing_defense_scene")
		return false
	var defense_node: Node2D = defense_scene.instantiate() as Node2D
	if defense_node == null:
		build_failed.emit("defense_scene_invalid")
		return false

	_defense_parent.add_child(defense_node)
	defense_node.global_position = pad.global_position
	defense_node.z_index = 30
	if defense_node.has_method("setup_from_def"):
		defense_node.call("setup_from_def", defense_def, _wave_controller)

	_occupied_pads[pad.get_instance_id()] = defense_node
	_defense_to_pad[defense_node.get_instance_id()] = pad
	if defense_node is DefenseActor:
		var actor: DefenseActor = defense_node as DefenseActor
		if not actor.is_connected("defense_clicked", _on_defense_clicked):
			actor.connect("defense_clicked", _on_defense_clicked)
	defense_built.emit(defense_id)
	return true

func reset_run_runtime() -> void:
	_occupied_pads.clear()
	_defense_to_pad.clear()
	_selected_defense = null

func select_defense(defense: DefenseActor) -> bool:
	if defense == null or not is_instance_valid(defense):
		_selected_defense = null
		return false
	_selected_defense = defense
	defense_selected.emit(defense, get_selected_refund_amount())
	return true

func get_selected_defense() -> DefenseActor:
	if _selected_defense == null or not is_instance_valid(_selected_defense):
		return null
	return _selected_defense

func get_selected_refund_amount() -> int:
	var defense: DefenseActor = get_selected_defense()
	if defense == null:
		return 0
	return _calculate_refund_amount(defense.base_cost)

func can_sell_selected_defense() -> bool:
	if _wave_controller == null:
		return false
	var defense: DefenseActor = get_selected_defense()
	if defense == null:
		return false
	return not _wave_controller.is_running()

func sell_selected_defense() -> int:
	if not can_sell_selected_defense():
		return 0
	var defense: DefenseActor = get_selected_defense()
	if defense == null:
		return 0
	var refund_amount: int = _calculate_refund_amount(defense.base_cost)
	if refund_amount > 0:
		_run_state().call("add_gold", refund_amount)
	_release_pad_for_defense(defense)
	var sold_defense_id: String = defense.defense_id
	defense.queue_free()
	_selected_defense = null
	defense_sold.emit(sold_defense_id, refund_amount)
	return refund_amount

func _is_category_compatible(defense_def: Resource, pad_category: String) -> bool:
	var defense_category: int = int(defense_def.get("category"))
	if pad_category.is_empty():
		return defense_category == DefenseDef.DefenseCategory.GROUND
	match pad_category:
		"ground":
			return defense_category == DefenseDef.DefenseCategory.GROUND
		"air":
			return defense_category == DefenseDef.DefenseCategory.AIR
		"wall":
			return defense_category == DefenseDef.DefenseCategory.WALL
		_:
			return false

func _run_state() -> Node:
	return get_node("/root/RunState")

func _content_db() -> Node:
	return get_node("/root/ContentDB")

func _on_defense_clicked(defense: DefenseActor) -> void:
	select_defense(defense)

func _calculate_refund_amount(base_cost: int) -> int:
	if base_cost <= 0:
		return 0
	var current_round: int = int(_run_state().get("current_round"))
	var ratio: float = 0.8 if current_round <= 2 else 0.7
	return int(floor(float(base_cost) * ratio))

func _release_pad_for_defense(defense: DefenseActor) -> void:
	if defense == null:
		return
	var defense_id: int = defense.get_instance_id()
	if not _defense_to_pad.has(defense_id):
		return
	var pad: Node = _defense_to_pad[defense_id]
	_defense_to_pad.erase(defense_id)
	if pad == null or not is_instance_valid(pad):
		return
	var pad_instance_id: int = pad.get_instance_id()
	if _occupied_pads.has(pad_instance_id):
		_occupied_pads.erase(pad_instance_id)
