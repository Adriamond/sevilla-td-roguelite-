extends Node2D

class_name EnemyActor

signal reached_end(enemy_id: String, leak_damage: int)
signal removed_from_wave(enemy_id: String)

const SPEED_SCALE: float = 42.0

var enemy_id: String = ""
var hp: float = 1.0
var speed: float = 1.0
var leak_damage: int = 1

var _path: Path2D = null
var _distance_travelled: float = 0.0
var _already_reached_end: bool = false

func setup_from_def(enemy_def: Resource, path: Path2D, is_elite: bool = false) -> void:
	enemy_id = String(enemy_def.get("id"))
	hp = float(enemy_def.get("base_hp"))
	speed = float(enemy_def.get("base_speed"))
	leak_damage = int(enemy_def.get("leak_damage"))

	if is_elite:
		hp *= 2.2

	_path = path
	_distance_travelled = 0.0
	_update_position()

func _process(delta: float) -> void:
	if _path == null:
		return
	var curve: Curve2D = _path.curve
	if curve == null:
		return

	var path_length: float = max(curve.get_baked_length(), 1.0)
	_distance_travelled += max(speed, 0.0) * SPEED_SCALE * delta
	if _distance_travelled >= path_length:
		if not _already_reached_end:
			_already_reached_end = true
			reached_end.emit(enemy_id, leak_damage)
		queue_free()
		return

	_update_position()

func _update_position() -> void:
	if _path == null:
		return
	var curve: Curve2D = _path.curve
	if curve == null:
		return
	var local_point: Vector2 = curve.sample_baked(_distance_travelled)
	global_position = _path.to_global(local_point)

func _exit_tree() -> void:
	removed_from_wave.emit(enemy_id)
