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
	var content_db_script: Script = load("res://autoload/content_db.gd")
	if content_db_script == null:
		print("Project validation failed: could not load ContentDB script.")
		quit(1)
		return
	var content_db: Node = content_db_script.new()
	if content_db == null:
		print("Project validation failed: could not instantiate ContentDB.")
		quit(1)
		return
	get_root().add_child(content_db)
	content_db.call("load_all")
	var map_validation: Dictionary = _validate_map_runtime_contracts(content_db)
	if not bool(map_validation.get("ok", false)):
		quit(1)
		return
	var validated_map_scene: PackedScene = map_validation.get("map_scene")
	var validated_map_id: String = String(map_validation.get("map_id", ""))
	if validated_map_scene == null:
		print("Project validation failed: no validated map scene available for runtime checks.")
		quit(1)
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

	var map_scene: PackedScene = validated_map_scene
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
		print("Project validation failed: validated map ", validated_map_id, " is missing MainPath/curve at runtime check.")
		quit(1)
		return
	if main_path.curve.get_baked_length() <= 0.0 and main_path.curve.get_point_count() < 2:
		print("Project validation failed: validated map ", validated_map_id, " has invalid MainPath length.")
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
	var manguerazo_base_damage: float = float(defense_instance.get("damage"))
	var manguerazo_base_range: float = float(defense_instance.get("attack_range"))
	var manguerazo_base_fire_rate: float = float(defense_instance.get("fire_rate"))
	if int(defense_instance.get("level")) != 1:
		print("Project validation failed: defense actor initial level should be 1.")
		quit(1)
		return
	if not bool(defense_instance.call("can_upgrade")):
		print("Project validation failed: defense actor should allow one upgrade at level 1.")
		quit(1)
		return
	if not bool(defense_instance.call("apply_upgrade")):
		print("Project validation failed: defense actor upgrade application failed.")
		quit(1)
		return
	if int(defense_instance.get("level")) != 2:
		print("Project validation failed: defense actor level should be 2 after upgrade.")
		quit(1)
		return
	if bool(defense_instance.call("can_upgrade")):
		print("Project validation failed: defense actor should not upgrade beyond level 2 in MVP.")
		quit(1)
		return
	var click_area: Node = defense_instance.get_node_or_null("%ClickArea")
	if click_area == null:
		print("Project validation failed: defense actor click area is missing for selection/selling flow.")
		quit(1)
		return
	var cable_def: Resource = load("res://data/defenses/cable_pelao.tres")
	if cable_def == null:
		print("Project validation failed: cable_pelao.tres could not be loaded.")
		quit(1)
		return
	var cable_instance: Node2D = defense_scene.instantiate() as Node2D
	if cable_instance == null:
		print("Project validation failed: could not instantiate second defense actor for cable_pelao.")
		quit(1)
		return
	get_root().add_child(cable_instance)
	if cable_instance.has_method("setup_from_def"):
		cable_instance.call("setup_from_def", cable_def, wave_controller)
	if String(cable_instance.get("defense_id")) != "cable_pelao":
		print("Project validation failed: defense actor did not initialize with cable_pelao.")
		quit(1)
		return
	if float(cable_instance.get("damage")) >= manguerazo_base_damage:
		print("Project validation failed: cable_pelao damage should be lower than manguerazo baseline.")
		quit(1)
		return
	if float(cable_instance.get("attack_range")) >= manguerazo_base_range:
		print("Project validation failed: cable_pelao range should be shorter than manguerazo baseline.")
		quit(1)
		return
	if float(cable_instance.get("fire_rate")) <= manguerazo_base_fire_rate:
		print("Project validation failed: cable_pelao fire_rate should be faster than manguerazo baseline.")
		quit(1)
		return
	var boss_def: Resource = load("res://data/enemies/killo_bulevar_boss.tres")
	if boss_def == null:
		print("Project validation failed: killo_bulevar_boss.tres could not be loaded.")
		quit(1)
		return
	var boss_scene: PackedScene = load(String(boss_def.get("scene_path")))
	if boss_scene == null:
		print("Project validation failed: boss enemy scene could not be loaded.")
		quit(1)
		return
	var boss_instance: Node2D = boss_scene.instantiate() as Node2D
	if boss_instance == null:
		print("Project validation failed: boss enemy scene could not instantiate.")
		quit(1)
		return
	get_root().add_child(boss_instance)
	if boss_instance.has_method("setup_from_def"):
		boss_instance.call("setup_from_def", boss_def, main_path, false)
	if not bool(boss_instance.call("is_alive")):
		print("Project validation failed: boss enemy did not initialize as alive actor.")
		quit(1)
		return
	boss_instance.queue_free()

	enemy_instance.queue_free()
	map_instance.queue_free()
	defense_instance.queue_free()
	cable_instance.queue_free()
	wave_controller.queue_free()
	content_db.queue_free()

	print("Project validation OK.")
	quit(0)

func _validate_map_runtime_contracts(content_db: Node) -> Dictionary:
	if content_db == null:
		print("Project validation failed: ContentDB missing for map contract validation.")
		return {"ok": false}
	var maps: Dictionary = content_db.get("maps")
	if maps.is_empty():
		print("Project validation failed: no maps loaded in ContentDB.")
		return {"ok": false}

	var sorted_map_ids: Array[String] = []
	for key: Variant in maps.keys():
		sorted_map_ids.append(String(key))
	sorted_map_ids.sort()

	var first_valid_map_scene: PackedScene = null
	var first_valid_map_id: String = ""

	for map_id: String in sorted_map_ids:
		var map_def: Resource = maps[map_id]
		if map_def == null:
			print("Map ", map_id, ": map resource is null.")
			return {"ok": false}
		var scene_path: String = String(map_def.get("scene_path")).strip_edges()
		if scene_path.is_empty():
			print("Map ", map_id, ": scene_path is empty.")
			return {"ok": false}
		if not ResourceLoader.exists(scene_path, "PackedScene"):
			print("Map ", map_id, ": scene_path does not exist: ", scene_path)
			return {"ok": false}
		var map_scene: PackedScene = load(scene_path)
		if map_scene == null:
			print("Map ", map_id, ": could not load scene ", scene_path)
			return {"ok": false}
		var map_instance: Node = map_scene.instantiate()
		if map_instance == null:
			print("Map ", map_id, ": could not instantiate scene ", scene_path)
			return {"ok": false}
		var map_root: Node2D = map_instance as Node2D
		if map_root == null:
			print("Map ", map_id, ": root is not Node2D-compatible.")
			map_instance.queue_free()
			return {"ok": false}
		get_root().add_child(map_root)
		map_root.call("_ready")

		var main_path: Path2D = map_root.get_node_or_null("MainPath")
		if main_path == null:
			print("Map ", map_id, ": missing MainPath.")
			map_root.queue_free()
			return {"ok": false}
		if main_path.curve == null:
			print("Map ", map_id, ": MainPath curve is null.")
			map_root.queue_free()
			return {"ok": false}
		if _curve_length(main_path.curve) <= 0.0:
			print("Map ", map_id, ": MainPath curve has zero baked/control length.")
			map_root.queue_free()
			return {"ok": false}

		var ground_path_ids: PackedStringArray = map_def.get("ground_path_ids")
		if not ground_path_ids.has("main"):
			print("Map ", map_id, ": ground_path_ids must include 'main' for current MVP runtime.")
			map_root.queue_free()
			return {"ok": false}
		var path_controller: PathController = PathController.new()
		path_controller.register_path("main", main_path)
		if path_controller.get_path_node("main") == null:
			print("Map ", map_id, ": failed to register/retrieve main path id.")
			map_root.queue_free()
			return {"ok": false}

		var start_marker: Node = map_root.get_node_or_null("StartMarker")
		if start_marker == null:
			print("Map ", map_id, ": missing StartMarker.")
			map_root.queue_free()
			return {"ok": false}
		var end_marker: Node = map_root.get_node_or_null("EndMarker")
		if end_marker == null:
			print("Map ", map_id, ": missing EndMarker.")
			map_root.queue_free()
			return {"ok": false}

		var pads_root: Node = map_root.get_node_or_null("BuildPads")
		if pads_root == null:
			print("Map ", map_id, ": missing BuildPads container.")
			map_root.queue_free()
			return {"ok": false}

		var pad_nodes: Array[Node] = []
		for child: Node in pads_root.get_children():
			var pad: Area2D = child as Area2D
			if pad == null:
				continue
			pad_nodes.append(pad)
		if pad_nodes.is_empty():
			print("Map ", map_id, ": no build pads found in BuildPads container.")
			map_root.queue_free()
			return {"ok": false}

		var used_pad_ids: Dictionary = {}
		for pad_node: Node in pad_nodes:
			var pad: Area2D = pad_node as Area2D
			if pad == null:
				print("Map ", map_id, ": null build pad node found.")
				map_root.queue_free()
				return {"ok": false}
			if not pad.has_signal("pad_clicked"):
				print("Map ", map_id, ": build pad ", pad.name, " missing pad_clicked signal.")
				map_root.queue_free()
				return {"ok": false}
			if pad.get_script() == null:
				print("Map ", map_id, ": build pad ", pad.name, " missing script.")
				map_root.queue_free()
				return {"ok": false}
			var pad_identifier: String = String(pad.get("pad_id")).strip_edges()
			if pad_identifier.is_empty():
				pad_identifier = String(pad.name)
			if pad_identifier.is_empty():
				print("Map ", map_id, ": build pad has no stable id or name.")
				map_root.queue_free()
				return {"ok": false}
			if used_pad_ids.has(pad_identifier):
				print("Map ", map_id, ": duplicate build pad id/name ", pad_identifier)
				map_root.queue_free()
				return {"ok": false}
			used_pad_ids[pad_identifier] = true

			var pad_category: String = String(pad.get("pad_category")).strip_edges()
			if pad_category.is_empty():
				print("Map ", map_id, ": build pad ", pad_identifier, " missing pad_category.")
				map_root.queue_free()
				return {"ok": false}

		var path_visual: Line2D = map_root.get_node_or_null("PathVisual")
		if path_visual != null and path_visual.points.size() >= 2:
			if _polyline_length(path_visual.points) <= 0.0:
				print("Map ", map_id, ": PathVisual exists but has zero length.")
				map_root.queue_free()
				return {"ok": false}

		if first_valid_map_scene == null:
			first_valid_map_scene = map_scene
			first_valid_map_id = map_id
		map_root.queue_free()

	return {"ok": true, "map_scene": first_valid_map_scene, "map_id": first_valid_map_id}

func _curve_length(curve: Curve2D) -> float:
	if curve == null:
		return 0.0
	var baked_length: float = curve.get_baked_length()
	if baked_length > 0.0:
		return baked_length
	var points: PackedVector2Array = curve.get_baked_points()
	if points.size() >= 2:
		return _polyline_length(points)
	var point_count: int = curve.get_point_count()
	if point_count < 2:
		return 0.0
	var control_points: PackedVector2Array = PackedVector2Array()
	for i: int in range(point_count):
		control_points.append(curve.get_point_position(i))
	return _polyline_length(control_points)

func _polyline_length(points: PackedVector2Array) -> float:
	if points.size() < 2:
		return 0.0
	var total: float = 0.0
	for i: int in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	return total

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
