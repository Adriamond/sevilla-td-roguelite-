extends Node

const DEBUG_SEED: int = 424242
const DEBUG_CHARACTER_ID: String = "manue_el_encerrado"
const DEBUG_MAP_ID: String = "pino_montano_bloques_bulevar"

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/menus/main_menu.tscn")
const ROOM_SCENE: PackedScene = preload("res://scenes/room/room_hub.tscn")
const GAMEPLAY_SCENE: PackedScene = preload("res://scenes/gameplay/gameplay_root.tscn")
const REWARD_SCENE: PackedScene = preload("res://scenes/ui/reward_screen.tscn")
const VICTORY_SCENE: PackedScene = preload("res://scenes/ui/victory_screen.tscn")
const DEFEAT_SCENE: PackedScene = preload("res://scenes/ui/defeat_screen.tscn")

var _run_controller: RunController
var _active_screen: Node = null
var _gameplay_screen: GameplayRootController = null
var _overlay_screen: Node = null
var _overlay_layer: CanvasLayer = null

func _ready() -> void:
	_run_controller = RunController.new()
	add_child(_run_controller)
	_run_controller.state_changed.connect(_on_run_state_changed)
	_run_controller.run_ended.connect(_on_run_ended)
	_show_main_menu()

func _show_main_menu() -> void:
	_cleanup_run_runtime()
	var menu: MainMenuController = _show_screen(MAIN_MENU_SCENE) as MainMenuController
	if menu == null:
		return
	menu.start_game_requested.connect(_on_start_game_requested)
	menu.quit_requested.connect(_on_quit_requested)

func _show_room() -> void:
	_clear_primary_screen()
	_set_gameplay_visible(false)
	var room: RoomScreenController = _show_overlay(ROOM_SCENE) as RoomScreenController
	if room == null:
		return
	var run_state: Node = _run_state()
	room.show_room()
	room.set_status(
		int(run_state.get("current_round")),
		int(run_state.get("gold")),
		int(run_state.get("core_hp"))
	)
	room.set_interactions(_run_controller.get_room_interaction_view_data())
	room.continue_requested.connect(_on_room_continue_requested)
	room.interaction_requested.connect(_on_room_interaction_requested)

func _show_build_phase() -> void:
	_clear_primary_screen()
	_clear_overlay()
	var gameplay_ui: GameplayRootController = _get_or_create_gameplay_screen()
	if gameplay_ui == null:
		return
	var round_def: Resource = _get_current_round_def()
	gameplay_ui.prepare_for_round(round_def)
	gameplay_ui.show_build_phase()
	_set_gameplay_visible(true)

func _show_wave_running() -> void:
	_clear_primary_screen()
	_clear_overlay()
	var gameplay_ui: GameplayRootController = _get_or_create_gameplay_screen()
	if gameplay_ui == null:
		return
	gameplay_ui.start_wave()
	if gameplay_ui.get_phase_name() != "WAVE_RUNNING":
		_run_controller.enter_build_phase()
		return
	_set_gameplay_visible(true)

func _show_reward_selection() -> void:
	_clear_primary_screen()
	_set_gameplay_visible(false)
	var reward_screen: RewardScreenController = _show_overlay(REWARD_SCENE) as RewardScreenController
	if reward_screen == null:
		return
	reward_screen.show_rewards(_get_placeholder_reward_ids())
	reward_screen.reward_chosen.connect(_on_reward_chosen)

func _show_victory() -> void:
	_cleanup_run_runtime()
	var victory_screen: EndScreenController = _show_screen(VICTORY_SCENE) as EndScreenController
	if victory_screen == null:
		return
	victory_screen.back_to_menu_requested.connect(_show_main_menu)

func _show_defeat() -> void:
	_cleanup_run_runtime()
	var defeat_screen: EndScreenController = _show_screen(DEFEAT_SCENE) as EndScreenController
	if defeat_screen == null:
		return
	defeat_screen.back_to_menu_requested.connect(_show_main_menu)

func _show_screen(scene: PackedScene) -> Node:
	if _active_screen != null and is_instance_valid(_active_screen):
		_active_screen.queue_free()
	_active_screen = scene.instantiate()
	add_child(_active_screen)
	return _active_screen

func _on_start_game_requested() -> void:
	_content_db().call("load_all")
	_cleanup_run_runtime()
	var gameplay_ui: GameplayRootController = _get_or_create_gameplay_screen()
	if gameplay_ui != null:
		gameplay_ui.reset_run_runtime()
	_set_gameplay_visible(false)
	_run_controller.start_run(DEBUG_SEED, DEBUG_CHARACTER_ID, DEBUG_MAP_ID)

func _on_quit_requested() -> void:
	get_tree().quit()

func _on_room_continue_requested() -> void:
	_run_controller.continue_from_room()

func _on_room_interaction_requested(interaction_id: String) -> void:
	var result: Dictionary = _run_controller.use_room_interaction(interaction_id)
	var room: RoomScreenController = _overlay_screen as RoomScreenController
	if room == null:
		return
	var run_state: Node = _run_state()
	room.set_status(
		int(run_state.get("current_round")),
		int(run_state.get("gold")),
		int(run_state.get("core_hp"))
	)
	room.set_interactions(_run_controller.get_room_interaction_view_data())
	room.set_message(String(result.get("message", "")))

func _on_start_wave_requested() -> void:
	_run_controller.start_current_wave()

func _on_force_complete_wave_requested() -> void:
	var gameplay_ui: GameplayRootController = _gameplay_screen
	if gameplay_ui == null:
		return
	gameplay_ui.force_complete_wave()

func _on_wave_completed() -> void:
	_run_controller.handle_wave_completed()

func _on_core_depleted() -> void:
	_run_controller.handle_core_depleted()

func _on_reward_chosen(item_id: String) -> void:
	_run_controller.accept_reward(item_id)

func _on_run_state_changed(new_state: RunController.RunStateType) -> void:
	match new_state:
		RunController.RunStateType.ROOM:
			_show_room()
		RunController.RunStateType.BUILD_PHASE:
			_show_build_phase()
		RunController.RunStateType.WAVE_RUNNING:
			_show_wave_running()
		RunController.RunStateType.REWARD_SELECTION:
			_show_reward_selection()
		RunController.RunStateType.VICTORY:
			_show_victory()
		RunController.RunStateType.DEFEAT:
			_show_defeat()

func _on_run_ended(_victory: bool) -> void:
	pass

func _get_or_create_gameplay_screen() -> GameplayRootController:
	if _gameplay_screen != null and is_instance_valid(_gameplay_screen):
		return _gameplay_screen

	_gameplay_screen = GAMEPLAY_SCENE.instantiate() as GameplayRootController
	if _gameplay_screen == null:
		return null
	add_child(_gameplay_screen)
	_gameplay_screen.start_wave_requested.connect(_on_start_wave_requested)
	_gameplay_screen.force_complete_wave_requested.connect(_on_force_complete_wave_requested)
	_gameplay_screen.wave_completed.connect(_on_wave_completed)
	_gameplay_screen.core_depleted.connect(_on_core_depleted)
	return _gameplay_screen

func _show_overlay(scene: PackedScene) -> Node:
	_clear_overlay()
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 50
	add_child(_overlay_layer)
	_overlay_screen = scene.instantiate()
	_overlay_layer.add_child(_overlay_screen)
	return _overlay_screen

func _clear_overlay() -> void:
	if _overlay_layer != null and is_instance_valid(_overlay_layer):
		_overlay_layer.queue_free()
	elif _overlay_screen != null and is_instance_valid(_overlay_screen):
		_overlay_screen.queue_free()
	_overlay_layer = null
	_overlay_screen = null

func _set_gameplay_visible(value: bool) -> void:
	if _gameplay_screen == null or not is_instance_valid(_gameplay_screen):
		return
	_gameplay_screen.set_gameplay_presentation_visible(value)

func _cleanup_run_runtime() -> void:
	_clear_overlay()
	if _gameplay_screen != null and is_instance_valid(_gameplay_screen):
		_gameplay_screen.queue_free()
	_gameplay_screen = null

func _clear_primary_screen() -> void:
	if _active_screen != null and is_instance_valid(_active_screen):
		_active_screen.queue_free()
	_active_screen = null

func _get_placeholder_reward_ids() -> Array[String]:
	var preferred_ids: Array[String] = [
		"litrito",
		"media_bellota",
		"rasta"
	]
	var result: Array[String] = []

	for item_id: String in preferred_ids:
		if _content_db().call("get_item", item_id) != null:
			result.append(item_id)

	if result.size() < 3:
		var fallback_ids: Array[String] = []
		for key: Variant in _content_db().get("items").keys():
			fallback_ids.append(String(key))
		fallback_ids.sort()
		for item_id: String in fallback_ids:
			if result.has(item_id):
				continue
			result.append(item_id)
			if result.size() == 3:
				break

	return result

func _run_state() -> Node:
	return get_node("/root/RunState")

func _content_db() -> Node:
	return get_node("/root/ContentDB")

func _get_current_round_def() -> Resource:
	return _run_controller.get_current_round_def()
