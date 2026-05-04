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

var _created_nodes: Array[Node] = []

func _init() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	print("Running project validation...")
	if not _validate_global_controller_scripts():
		await _fail("Project validation failed: global controller script validation failed.")
		return

	var content_db_script: Script = load("res://autoload/content_db.gd")
	if content_db_script == null:
		await _fail("Project validation failed: could not load ContentDB script.")
		return
	var content_db: Node = content_db_script.new()
	if content_db == null:
		await _fail("Project validation failed: could not instantiate ContentDB.")
		return
	_track_node(content_db)
	content_db.call("load_all")

	var map_validation: Dictionary = _validate_map_runtime_contracts(content_db)
	if not bool(map_validation.get("ok", false)):
		await _fail("Project validation failed: map runtime contract validation failed.")
		return
	var validated_map_scene: PackedScene = map_validation.get("map_scene")
	var validated_map_id: String = String(map_validation.get("map_id", ""))
	if validated_map_scene == null:
		await _fail("Project validation failed: no validated map scene available for runtime checks.")
		return

	for scene_spec: Dictionary in SCENE_SPECS:
		var scene_path: String = scene_spec.get("scene", "")
		var root_script_path: String = scene_spec.get("root_script", "")

		var scene: PackedScene = load(scene_path)
		if scene == null:
			await _fail("Project validation failed: could not load scene: %s" % scene_path)
			return

		var instance: Node = scene.instantiate()
		if instance == null:
			await _fail("Project validation failed: could not instantiate scene: %s" % scene_path)
			return

		if not root_script_path.is_empty():
			var root_script: Script = instance.get_script()
			if root_script == null:
				await _fail("Project validation failed: root script did not compile for scene: %s" % scene_path)
				return
			if root_script.resource_path != root_script_path:
				await _fail("Project validation failed: unexpected root script for scene: %s" % scene_path)
				return

		instance.free()

	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var defense_scene: PackedScene = load("res://scenes/defenses/defense_base.tscn")
	if enemy_scene == null or defense_scene == null:
		await _fail("Project validation failed: map/enemy/defense scene load check failed.")
		return

	var map_instance: Node2D = validated_map_scene.instantiate() as Node2D
	var enemy_instance: Node2D = enemy_scene.instantiate() as Node2D
	var defense_instance: Node2D = defense_scene.instantiate() as Node2D
	if map_instance == null or enemy_instance == null or defense_instance == null:
		await _fail("Project validation failed: map/enemy/defense instantiate check failed.")
		return

	_track_node(map_instance)
	_track_node(enemy_instance)
	_track_node(defense_instance)
	map_instance.call("_ready")

	var main_path: Path2D = map_instance.get_node_or_null("MainPath")
	if main_path == null or main_path.curve == null:
		await _fail("Project validation failed: validated map %s is missing MainPath/curve at runtime check." % validated_map_id)
		return
	if main_path.curve.get_baked_length() <= 0.0 and main_path.curve.get_point_count() < 2:
		await _fail("Project validation failed: validated map %s has invalid MainPath length." % validated_map_id)
		return

	var enemy_def: Resource = load("res://data/enemies/tactichandal_runner.tres")
	if enemy_def == null:
		await _fail("Project validation failed: tactichandal_runner.tres could not be loaded.")
		return
	if enemy_instance.has_method("setup_from_def"):
		enemy_instance.call("setup_from_def", enemy_def, main_path, false)
	if enemy_instance.has_method("_process"):
		enemy_instance.call("_process", 0.1)
	if enemy_instance.global_position == Vector2.ZERO:
		await _fail("Project validation failed: enemy did not move to path space after setup.")
		return
	if enemy_instance.has_method("apply_damage"):
		var hp_before: float = float(enemy_instance.get("current_hp"))
		enemy_instance.call("apply_damage", 1.0)
		var hp_after: float = float(enemy_instance.get("current_hp"))
		if hp_after >= hp_before:
			await _fail("Project validation failed: enemy apply_damage did not reduce current_hp.")
			return
	if not bool(enemy_instance.call("is_alive")):
		await _fail("Project validation failed: enemy should remain alive after non-lethal damage sanity check.")
		return

	var defense_def: Resource = load("res://data/defenses/manguerazo.tres")
	if defense_def == null:
		await _fail("Project validation failed: manguerazo.tres could not be loaded.")
		return
	var wave_controller_script: Script = load("res://scripts/gameplay/wave_controller.gd")
	if wave_controller_script == null:
		await _fail("Project validation failed: could not load wave_controller.gd.")
		return
	var wave_controller: Node = wave_controller_script.new()
	_track_node(wave_controller)
	if defense_instance.has_method("setup_from_def"):
		defense_instance.call("setup_from_def", defense_def, wave_controller)
	if String(defense_instance.get("defense_id")) != "manguerazo":
		await _fail("Project validation failed: defense actor did not initialize with manguerazo.")
		return
	var manguerazo_base_damage: float = float(defense_instance.get("damage"))
	var manguerazo_base_range: float = float(defense_instance.get("attack_range"))
	var manguerazo_base_fire_rate: float = float(defense_instance.get("fire_rate"))
	if int(defense_instance.get("level")) != 1:
		await _fail("Project validation failed: defense actor initial level should be 1.")
		return
	if not bool(defense_instance.call("can_upgrade")):
		await _fail("Project validation failed: defense actor should allow one upgrade at level 1.")
		return
	if not bool(defense_instance.call("apply_upgrade")):
		await _fail("Project validation failed: defense actor upgrade application failed.")
		return
	if int(defense_instance.get("level")) != 2:
		await _fail("Project validation failed: defense actor level should be 2 after upgrade.")
		return
	if bool(defense_instance.call("can_upgrade")):
		await _fail("Project validation failed: defense actor should not upgrade beyond level 2 in MVP.")
		return
	var click_area: Node = defense_instance.get_node_or_null("%ClickArea")
	if click_area == null:
		await _fail("Project validation failed: defense actor click area is missing for selection/selling flow.")
		return

	var cable_def: Resource = load("res://data/defenses/cable_pelao.tres")
	if cable_def == null:
		await _fail("Project validation failed: cable_pelao.tres could not be loaded.")
		return
	var cable_instance: Node2D = defense_scene.instantiate() as Node2D
	if cable_instance == null:
		await _fail("Project validation failed: could not instantiate second defense actor for cable_pelao.")
		return
	_track_node(cable_instance)
	if cable_instance.has_method("setup_from_def"):
		cable_instance.call("setup_from_def", cable_def, wave_controller)
	if String(cable_instance.get("defense_id")) != "cable_pelao":
		await _fail("Project validation failed: defense actor did not initialize with cable_pelao.")
		return
	if float(cable_instance.get("damage")) >= manguerazo_base_damage:
		await _fail("Project validation failed: cable_pelao damage should be lower than manguerazo baseline.")
		return
	if float(cable_instance.get("attack_range")) >= manguerazo_base_range:
		await _fail("Project validation failed: cable_pelao range should be shorter than manguerazo baseline.")
		return
	if float(cable_instance.get("fire_rate")) <= manguerazo_base_fire_rate:
		await _fail("Project validation failed: cable_pelao fire_rate should be faster than manguerazo baseline.")
		return

	var boss_def: Resource = load("res://data/enemies/killo_bulevar_boss.tres")
	if boss_def == null:
		await _fail("Project validation failed: killo_bulevar_boss.tres could not be loaded.")
		return
	var boss_scene: PackedScene = load(String(boss_def.get("scene_path")))
	if boss_scene == null:
		await _fail("Project validation failed: boss enemy scene could not be loaded.")
		return
	var boss_instance: Node2D = boss_scene.instantiate() as Node2D
	if boss_instance == null:
		await _fail("Project validation failed: boss enemy scene could not instantiate.")
		return
	_track_node(boss_instance)
	if boss_instance.has_method("setup_from_def"):
		boss_instance.call("setup_from_def", boss_def, main_path, false)
	if not bool(boss_instance.call("is_alive")):
		await _fail("Project validation failed: boss enemy did not initialize as alive actor.")
		return

	await _cleanup_created_nodes()
	print("Project validation OK.")
	call_deferred("_exit_with_code", 0)
	return

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
			map_instance.free()
			return {"ok": false}

		_track_node(map_root)
		map_root.call("_ready")

		var main_path: Path2D = map_root.get_node_or_null("MainPath")
		if main_path == null:
			print("Map ", map_id, ": missing MainPath.")
			return {"ok": false}
		if main_path.curve == null:
			print("Map ", map_id, ": MainPath curve is null.")
			return {"ok": false}
		if _curve_length(main_path.curve) <= 0.0:
			print("Map ", map_id, ": MainPath curve has zero baked/control length.")
			return {"ok": false}

		var ground_path_ids: PackedStringArray = map_def.get("ground_path_ids")
		if not ground_path_ids.has("main"):
			print("Map ", map_id, ": ground_path_ids must include 'main' for current MVP runtime.")
			return {"ok": false}

		var start_marker: Node = map_root.get_node_or_null("StartMarker")
		if start_marker == null:
			print("Map ", map_id, ": missing StartMarker.")
			return {"ok": false}
		var end_marker: Node = map_root.get_node_or_null("EndMarker")
		if end_marker == null:
			print("Map ", map_id, ": missing EndMarker.")
			return {"ok": false}

		var pads_root: Node = map_root.get_node_or_null("BuildPads")
		if pads_root == null:
			print("Map ", map_id, ": missing BuildPads container.")
			return {"ok": false}

		var pad_nodes: Array[Node] = []
		for child: Node in pads_root.get_children():
			var pad: Area2D = child as Area2D
			if pad == null:
				continue
			pad_nodes.append(pad)
		if pad_nodes.is_empty():
			print("Map ", map_id, ": no build pads found in BuildPads container.")
			return {"ok": false}

		var used_pad_ids: Dictionary = {}
		for pad_node: Node in pad_nodes:
			var pad: Area2D = pad_node as Area2D
			if pad == null:
				print("Map ", map_id, ": null build pad node found.")
				return {"ok": false}
			if not pad.has_signal("pad_clicked"):
				print("Map ", map_id, ": build pad ", pad.name, " missing pad_clicked signal.")
				return {"ok": false}
			if pad.get_script() == null:
				print("Map ", map_id, ": build pad ", pad.name, " missing script.")
				return {"ok": false}
			var pad_identifier: String = String(pad.get("pad_id")).strip_edges()
			if pad_identifier.is_empty():
				pad_identifier = String(pad.name)
			if pad_identifier.is_empty():
				print("Map ", map_id, ": build pad has no stable id or name.")
				return {"ok": false}
			if used_pad_ids.has(pad_identifier):
				print("Map ", map_id, ": duplicate build pad id/name ", pad_identifier)
				return {"ok": false}
			used_pad_ids[pad_identifier] = true
			var pad_category: String = String(pad.get("pad_category")).strip_edges()
			if pad_category.is_empty():
				print("Map ", map_id, ": build pad ", pad_identifier, " missing pad_category.")
				return {"ok": false}

		var path_visual: Line2D = map_root.get_node_or_null("PathVisual")
		if path_visual != null and path_visual.points.size() >= 2:
			if _polyline_length(path_visual.points) <= 0.0:
				print("Map ", map_id, ": PathVisual exists but has zero length.")
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
			return false
		var script_instance: Object = script_res.new()
		if script_instance == null:
			print("Project validation failed: could not instantiate script: ", script_path)
			return false
		if script_instance is Node:
			(script_instance as Node).free()
	return true

func _track_node(node: Node) -> void:
	if node == null:
		return
	get_root().add_child(node)
	_created_nodes.append(node)

func _cleanup_created_nodes() -> void:
	for i: int in range(_created_nodes.size() - 1, -1, -1):
		var node: Node = _created_nodes[i]
		if node == null or not is_instance_valid(node):
			continue
		node.queue_free()
	_created_nodes.clear()
	await process_frame
	await process_frame
	await process_frame
	await create_timer(0.3).timeout

func _fail(message: String) -> void:
	push_error(message)
	await _cleanup_created_nodes()
	call_deferred("_exit_with_code", 1)

func _exit_with_code(code: int) -> void:
	quit(code)
