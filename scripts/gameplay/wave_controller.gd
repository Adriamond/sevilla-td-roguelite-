extends Node

class_name WaveController

signal wave_started(round_index: int)
signal wave_completed(round_index: int)
signal enemy_leaked(enemy_id: String, leak_damage: int)
signal active_enemy_count_changed(value: int)

var active_round_def: Resource
var _spawn_controller: SpawnController = null
var _active_enemies: Dictionary = {}
var _spawn_sequence_done: bool = false
var _running: bool = false
var _cancel_requested: bool = false

func configure(spawn_controller: SpawnController) -> void:
	_spawn_controller = spawn_controller

func start_round(round_def: Resource) -> void:
	if _spawn_controller == null or round_def == null:
		return

	active_round_def = round_def
	_active_enemies.clear()
	_spawn_sequence_done = false
	_running = true
	_cancel_requested = false

	var run_state: Node = get_node("/root/RunState")
	wave_started.emit(int(run_state.get("current_round")))
	_spawn_round_steps()

func complete_wave() -> void:
	if not _running:
		return
	_running = false
	var run_state: Node = get_node("/root/RunState")
	wave_completed.emit(int(run_state.get("current_round")))

func debug_force_complete() -> void:
	_cancel_requested = true
	for key: Variant in _active_enemies.keys():
		var enemy: Node = _active_enemies[key]
		if enemy != null and is_instance_valid(enemy):
			enemy.queue_free()
	_active_enemies.clear()
	active_enemy_count_changed.emit(0)
	_spawn_sequence_done = true
	_check_wave_completion()

func get_active_enemy_count() -> int:
	return _active_enemies.size()

func _spawn_round_steps() -> void:
	_spawn_round_steps_async()

func _spawn_round_steps_async() -> void:
	var steps: Array = active_round_def.get("wave_steps")
	for step_variant: Variant in steps:
		if _cancel_requested:
			break
		if step_variant == null or not (step_variant is Resource):
			continue
		var step: Resource = step_variant

		var start_delay: float = float(step.get("start_delay"))
		if start_delay > 0.0:
			await get_tree().create_timer(start_delay).timeout
			if _cancel_requested:
				break

		var count: int = int(step.get("count"))
		var spawn_interval: float = float(step.get("spawn_interval"))
		var enemy_id: String = String(step.get("enemy_id"))
		var path_id: String = String(step.get("path_id"))
		var is_elite: bool = bool(step.get("is_elite"))

		for i: int in range(count):
			if _cancel_requested:
				break
			var enemy: Node = _spawn_controller.spawn_enemy(enemy_id, path_id, is_elite)
			if enemy != null:
				_register_enemy(enemy)
			if i < count - 1 and spawn_interval > 0.0:
				await get_tree().create_timer(spawn_interval).timeout

	_spawn_sequence_done = true
	_check_wave_completion()

func _register_enemy(enemy: Node) -> void:
	var id: int = enemy.get_instance_id()
	_active_enemies[id] = enemy
	active_enemy_count_changed.emit(_active_enemies.size())

	if enemy.has_signal("reached_end"):
		enemy.reached_end.connect(_on_enemy_reached_end)
	if enemy.has_signal("removed_from_wave"):
		enemy.removed_from_wave.connect(_on_enemy_removed_from_wave.bind(id))

func _on_enemy_reached_end(enemy_id: String, leak_damage: int) -> void:
	enemy_leaked.emit(enemy_id, leak_damage)

func _on_enemy_removed_from_wave(_enemy_id: String, instance_id: int) -> void:
	if not _active_enemies.has(instance_id):
		return
	_active_enemies.erase(instance_id)
	active_enemy_count_changed.emit(_active_enemies.size())
	_check_wave_completion()

func _check_wave_completion() -> void:
	if not _running:
		return
	if not _spawn_sequence_done:
		return
	if _active_enemies.size() > 0:
		return
	complete_wave()
