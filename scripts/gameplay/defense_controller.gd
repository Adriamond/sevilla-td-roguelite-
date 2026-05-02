extends Node

class_name DefenseController

signal defense_built(defense_id: String)
signal build_failed(reason: String)

var _defense_parent: Node2D = null
var _wave_controller: WaveController = null
var _occupied_pads: Dictionary = {}

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
	defense_built.emit(defense_id)
	return true

func reset_run_runtime() -> void:
	_occupied_pads.clear()

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
