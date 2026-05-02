extends Node

class_name SpawnController

var _enemy_parent: Node2D = null
var _path_controller: PathController = null

func configure(enemy_parent: Node2D, path_controller: PathController) -> void:
	_enemy_parent = enemy_parent
	_path_controller = path_controller

func spawn_enemy(enemy_id: String, path_id: String = "main", is_elite: bool = false) -> Node:
	if _enemy_parent == null or _path_controller == null:
		return null

	var content_db: Node = get_node("/root/ContentDB")
	var enemy_def: Resource = content_db.call("get_enemy", enemy_id)
	if enemy_def == null:
		push_warning("Missing EnemyDef for id: %s" % enemy_id)
		return null

	var enemy_scene_path: String = String(enemy_def.get("scene_path"))
	var enemy_scene: PackedScene = load(enemy_scene_path)
	if enemy_scene == null:
		push_warning("Failed to load enemy scene: %s" % enemy_scene_path)
		return null

	var enemy_node: Node = enemy_scene.instantiate()
	if enemy_node == null:
		return null

	_enemy_parent.add_child(enemy_node)

	var path: Path2D = _path_controller.get_path_node(path_id)
	if path == null:
		path = _path_controller.get_path_node("main")
	if path == null or path.curve == null or path.curve.get_point_count() < 2:
		push_warning("Missing or invalid path for enemy spawn (enemy_id=%s, path_id=%s)." % [enemy_id, path_id])
		enemy_node.queue_free()
		return null

	if enemy_node.has_method("setup_from_def"):
		enemy_node.call("setup_from_def", enemy_def, path, is_elite)

	return enemy_node
