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

func _ready() -> void:
	_run_controller = RunController.new()
	add_child(_run_controller)
	_run_controller.state_changed.connect(_on_run_state_changed)
	_run_controller.run_ended.connect(_on_run_ended)
	_show_main_menu()

func _show_main_menu() -> void:
	var menu: MainMenuController = _show_screen(MAIN_MENU_SCENE) as MainMenuController
	if menu == null:
		return
	menu.start_game_requested.connect(_on_start_game_requested)
	menu.quit_requested.connect(_on_quit_requested)

func _show_room() -> void:
	var room: RoomScreenController = _show_screen(ROOM_SCENE) as RoomScreenController
	if room == null:
		return
	var run_state: Node = _run_state()
	room.show_room()
	room.set_status(
		int(run_state.get("current_round")),
		int(run_state.get("gold")),
		int(run_state.get("core_hp"))
	)
	room.continue_requested.connect(_on_room_continue_requested)

func _show_build_phase() -> void:
	var gameplay_ui: GameplayRootController = _show_screen(GAMEPLAY_SCENE) as GameplayRootController
	if gameplay_ui == null:
		return
	gameplay_ui.show_build_phase()
	gameplay_ui.start_dummy_wave_requested.connect(_on_start_dummy_wave_requested)
	gameplay_ui.complete_dummy_wave_requested.connect(_on_complete_dummy_wave_requested)

func _show_wave_running() -> void:
	var gameplay_ui: GameplayRootController = _show_screen(GAMEPLAY_SCENE) as GameplayRootController
	if gameplay_ui == null:
		return
	gameplay_ui.show_wave_running()
	gameplay_ui.start_dummy_wave_requested.connect(_on_start_dummy_wave_requested)
	gameplay_ui.complete_dummy_wave_requested.connect(_on_complete_dummy_wave_requested)

func _show_reward_selection() -> void:
	var reward_screen: RewardScreenController = _show_screen(REWARD_SCENE) as RewardScreenController
	if reward_screen == null:
		return
	reward_screen.show_rewards(_get_placeholder_reward_ids())
	reward_screen.reward_chosen.connect(_on_reward_chosen)

func _show_victory() -> void:
	var victory_screen: EndScreenController = _show_screen(VICTORY_SCENE) as EndScreenController
	if victory_screen == null:
		return
	victory_screen.back_to_menu_requested.connect(_show_main_menu)

func _show_defeat() -> void:
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
	_run_controller.start_run(DEBUG_SEED, DEBUG_CHARACTER_ID, DEBUG_MAP_ID)

func _on_quit_requested() -> void:
	get_tree().quit()

func _on_room_continue_requested() -> void:
	_run_controller.transition_to(RunController.RunStateType.BUILD_PHASE)

func _on_start_dummy_wave_requested() -> void:
	_run_controller.transition_to(RunController.RunStateType.WAVE_RUNNING)

func _on_complete_dummy_wave_requested() -> void:
	var run_state: Node = _run_state()
	if int(run_state.get("core_hp")) <= 0:
		_run_controller.end_run(false)
		return

	var current_round: int = int(run_state.get("current_round"))
	var round_reward_gold: int = 45 + 15 * current_round
	run_state.call("add_gold", round_reward_gold)
	_run_controller.transition_to(RunController.RunStateType.REWARD_SELECTION)

func _on_reward_chosen(item_id: String) -> void:
	if item_id.is_empty():
		return
	var run_state: Node = _run_state()
	var picked_item_ids: Array[String] = run_state.get("picked_item_ids")
	picked_item_ids.append(item_id)
	run_state.set("picked_item_ids", picked_item_ids)

	var current_round: int = int(run_state.get("current_round"))
	if current_round >= 6:
		_run_controller.end_run(true)
		return

	run_state.set("current_round", current_round + 1)
	run_state.get("round_changed").emit(int(run_state.get("current_round")))
	_run_controller.transition_to(RunController.RunStateType.ROOM)

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

func _get_placeholder_reward_ids() -> Array[String]:
	var preferred_ids: Array[String] = [
		"botellin_congelado",
		"abanico_prestado",
        "ticket_bus_urbano"
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
