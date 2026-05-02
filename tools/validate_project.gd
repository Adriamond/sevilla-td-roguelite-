extends SceneTree

const SCENE_SPECS: Array[Dictionary] = [
	{"scene": "res://scenes/boot/boot.tscn", "root_script": "res://scripts/ui/boot_controller.gd"},
	{"scene": "res://scenes/menus/main_menu.tscn", "root_script": "res://scripts/ui/main_menu_controller.gd"},
	{"scene": "res://scenes/room/room_hub.tscn", "root_script": "res://scripts/ui/room_screen_controller.gd"},
	{"scene": "res://scenes/gameplay/gameplay_root.tscn", "root_script": "res://scripts/ui/gameplay_root_controller.gd"},
	{"scene": "res://scenes/ui/reward_screen.tscn", "root_script": "res://scripts/ui/reward_screen_controller.gd"},
	{"scene": "res://scenes/ui/victory_screen.tscn", "root_script": "res://scripts/ui/end_screen_controller.gd"},
	{"scene": "res://scenes/ui/defeat_screen.tscn", "root_script": "res://scripts/ui/end_screen_controller.gd"},
	{"scene": "res://scenes/maps/pino_montano/pino_montano_map.tscn", "root_script": ""},
	{"scene": "res://scenes/enemies/enemy_base.tscn", "root_script": "res://scripts/gameplay/enemy_actor.gd"},
	{"scene": "res://scenes/defenses/defense_base.tscn", "root_script": "res://scripts/gameplay/defense_actor.gd"}
]

func _init() -> void:
	print("Running project validation...")
	if not _validate_global_controller_scripts():
		return

	for scene_spec: Dictionary in SCENE_SPECS:
		var scene_path: String = scene_spec.get("scene", "")
		var root_script_path: String = scene_spec.get("root_script", "")

		var scene: PackedScene = load(scene_path)
		if scene == null:
			print("Project validation failed: could not load scene: ", scene_path)
			quit(1)
			return

		var instance: Node = scene.instantiate()
		if instance == null:
			print("Project validation failed: could not instantiate scene: ", scene_path)
			quit(1)
			return

		if not root_script_path.is_empty():
			var root_script: Script = instance.get_script()
			if root_script == null:
				print("Project validation failed: root script did not compile for scene: ", scene_path)
				quit(1)
				return
			if root_script.resource_path != root_script_path:
				print("Project validation failed: unexpected root script for scene: ", scene_path)
				print("Expected: ", root_script_path, " | Got: ", root_script.resource_path)
				quit(1)
				return

		instance.queue_free()

	var map_scene: PackedScene = load("res://scenes/maps/pino_montano/pino_montano_map.tscn")
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var defense_scene: PackedScene = load("res://scenes/defenses/defense_base.tscn")
	if map_scene == null or enemy_scene == null or defense_scene == null:
		print("Project validation failed: map/enemy/defense scene load check failed.")
		quit(1)
		return

	var map_instance: Node2D = map_scene.instantiate() as Node2D
	var enemy_instance: Node2D = enemy_scene.instantiate() as Node2D
	var defense_instance: Node2D = defense_scene.instantiate() as Node2D
	if map_instance == null or enemy_instance == null or defense_instance == null:
		print("Project validation failed: map/enemy/defense instantiate check failed.")
		quit(1)
		return

	get_root().add_child(map_instance)
	get_root().add_child(enemy_instance)
	get_root().add_child(defense_instance)
	map_instance.call("_ready")

	var main_path: Path2D = map_instance.get_node_or_null("MainPath")
	if main_path == null or main_path.curve == null:
		print("Project validation failed: MainPath or MainPath.curve is missing.")
		quit(1)
		return
	if main_path.curve.get_baked_length() <= 0.0 and main_path.curve.get_point_count() < 2:
		print("Project validation failed: MainPath has insufficient points/length.")
		quit(1)
		return

	var enemy_def: Resource = load("res://data/enemies/tactichandal_runner.tres")
	if enemy_def == null:
		print("Project validation failed: tactichandal_runner.tres could not be loaded.")
		quit(1)
		return
	if enemy_instance.has_method("setup_from_def"):
		enemy_instance.call("setup_from_def", enemy_def, main_path, false)
	if enemy_instance.has_method("_process"):
		enemy_instance.call("_process", 0.1)
	if enemy_instance.global_position == Vector2.ZERO:
		print("Project validation failed: enemy did not move to path space after setup.")
		quit(1)
		return
	if enemy_instance.has_method("apply_damage"):
		enemy_instance.call("apply_damage", 9999.0)
	if bool(enemy_instance.call("is_alive")):
		print("Project validation failed: enemy apply_damage did not kill enemy.")
		quit(1)
		return

	var defense_def: Resource = load("res://data/defenses/manguerazo.tres")
	if defense_def == null:
		print("Project validation failed: manguerazo.tres could not be loaded.")
		quit(1)
		return
	var wave_controller_script: Script = load("res://scripts/gameplay/wave_controller.gd")
	var wave_controller: Node = wave_controller_script.new()
	get_root().add_child(wave_controller)
	if defense_instance.has_method("setup_from_def"):
		defense_instance.call("setup_from_def", defense_def, wave_controller)
	if String(defense_instance.get("defense_id")) != "manguerazo":
		print("Project validation failed: defense actor did not initialize with manguerazo.")
		quit(1)
		return

	enemy_instance.queue_free()
	map_instance.queue_free()
	defense_instance.queue_free()
	wave_controller.queue_free()

	print("Project validation OK.")
	quit(0)

func _validate_global_controller_scripts() -> bool:
	var required_scripts: Array[String] = [
		"res://scripts/gameplay/spawn_controller.gd",
		"res://scripts/gameplay/wave_controller.gd"
	]
	for script_path: String in required_scripts:
		var script_res: Script = load(script_path)
		if script_res == null:
			print("Project validation failed: could not load script: ", script_path)
			quit(1)
			return false
		var script_instance: Object = script_res.new()
		if script_instance == null:
			print("Project validation failed: could not instantiate script: ", script_path)
			quit(1)
			return false
		if script_instance is Node:
			(script_instance as Node).queue_free()
	return true
