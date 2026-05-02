extends Node2D

class_name GameplayRootController

signal start_wave_requested
signal force_complete_wave_requested
signal wave_completed
signal core_depleted

@onready var phase_label: Label = %PhaseLabel
@onready var round_label: Label = %RoundValueLabel
@onready var action_button: Button = %PhaseActionButton
@onready var force_complete_button: Button = %ForceCompleteButton
@onready var core_hp_label: Label = %CoreHPValueLabel
@onready var active_enemies_label: Label = %ActiveEnemiesValueLabel
@onready var map_container: Node2D = %MapContainer
@onready var enemy_layer: Node2D = %EnemyLayer
@onready var path_controller: PathController = %PathController
@onready var spawn_controller: SpawnController = %SpawnController
@onready var wave_controller: WaveController = %WaveController

var _is_wave_running: bool = false
var _map_instance: Node2D = null
var _active_round_def: Resource = null

func show_build_phase() -> void:
	_is_wave_running = false
	phase_label.text = "Build Phase"
	action_button.text = "Start Wave"
	force_complete_button.visible = false
	_update_status_labels()

func show_wave_running() -> void:
	_is_wave_running = true
	phase_label.text = "Wave Running"
	action_button.text = "Wave Running..."
	force_complete_button.visible = true
	_update_status_labels()

func request_phase_action() -> void:
	if _is_wave_running:
		return
	start_wave_requested.emit()

func request_force_complete() -> void:
	if not _is_wave_running:
		return
	force_complete_wave_requested.emit()

func prepare_round(round_def: Resource) -> void:
	_active_round_def = round_def
	_ensure_map_loaded()
	_update_status_labels()

func start_wave() -> void:
	if _active_round_def == null:
		return
	_is_wave_running = true
	show_wave_running()
	wave_controller.start_round(_active_round_def)

func force_complete_wave() -> void:
	wave_controller.debug_force_complete()

func _ready() -> void:
	spawn_controller.configure(enemy_layer, path_controller)
	wave_controller.configure(spawn_controller)
	wave_controller.wave_completed.connect(_on_wave_completed)
	wave_controller.enemy_leaked.connect(_on_enemy_leaked)
	wave_controller.active_enemy_count_changed.connect(_on_active_enemy_count_changed)
	_center_camera()
	_update_status_labels()

func _ensure_map_loaded() -> void:
	if _map_instance != null and is_instance_valid(_map_instance):
		return

	var map_scene: PackedScene = null
	var run_state: Node = get_node("/root/RunState")
	var content_db: Node = get_node("/root/ContentDB")
	var map_id: String = String(run_state.get("map_id"))
	var map_def: Resource = content_db.call("get_map", map_id)
	if map_def != null:
		var scene_path: String = String(map_def.get("scene_path"))
		map_scene = load(scene_path) as PackedScene

	if map_scene == null:
		map_scene = load("res://scenes/maps/pino_montano/pino_montano_map.tscn")
	if map_scene == null:
		return

	_map_instance = map_scene.instantiate() as Node2D
	if _map_instance == null:
		return

	map_container.add_child(_map_instance)
	path_controller.clear_paths()
	var main_path: Path2D = _map_instance.get_node_or_null("MainPath")
	if main_path != null:
		path_controller.register_path("main", main_path)

func _center_camera() -> void:
	var camera: Camera2D = get_node_or_null("MainCamera")
	if camera == null:
		return
	camera.position = Vector2(480, 270)

func _on_wave_completed(_round_index: int) -> void:
	_is_wave_running = false
	wave_completed.emit()

func _on_enemy_leaked(_enemy_id: String, leak_damage: int) -> void:
	var run_state: Node = get_node("/root/RunState")
	run_state.call("damage_core", leak_damage)
	_update_status_labels()
	if bool(run_state.call("is_defeated")):
		core_depleted.emit()

func _on_active_enemy_count_changed(_value: int) -> void:
	_update_status_labels()

func _update_status_labels() -> void:
	var run_state: Node = get_node("/root/RunState")
	round_label.text = str(int(run_state.get("current_round")))
	core_hp_label.text = str(int(run_state.get("core_hp")))
	active_enemies_label.text = str(wave_controller.get_active_enemy_count())
