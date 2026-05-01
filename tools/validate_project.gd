extends SceneTree

const SCENE_SPECS: Array[Dictionary] = [
	{"scene": "res://scenes/boot/boot.tscn", "root_script": "res://scripts/ui/boot_controller.gd"},
	{"scene": "res://scenes/menus/main_menu.tscn", "root_script": "res://scripts/ui/main_menu_controller.gd"},
	{"scene": "res://scenes/room/room_hub.tscn", "root_script": "res://scripts/ui/room_screen_controller.gd"},
	{"scene": "res://scenes/gameplay/gameplay_root.tscn", "root_script": "res://scripts/ui/gameplay_root_controller.gd"},
	{"scene": "res://scenes/ui/reward_screen.tscn", "root_script": "res://scripts/ui/reward_screen_controller.gd"},
	{"scene": "res://scenes/ui/victory_screen.tscn", "root_script": "res://scripts/ui/end_screen_controller.gd"},
	{"scene": "res://scenes/ui/defeat_screen.tscn", "root_script": "res://scripts/ui/end_screen_controller.gd"}
]

func _init() -> void:
	print("Running project validation...")

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

	print("Project validation OK.")
	quit(0)
