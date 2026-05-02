extends SceneTree

const DEBUG_SEED: int = 424242
const DEBUG_CHARACTER_ID: String = "manue_el_encerrado"
const DEBUG_MAP_ID: String = "pino_montano_bloques_bulevar"

var _created_nodes: Array[Node] = []

func _init() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	print("Running flow smoke validation...")

	var run_state: Node = _ensure_singleton("RunState", "res://autoload/run_state.gd")
	var content_db: Node = _ensure_singleton("ContentDB", "res://autoload/content_db.gd")
	if run_state == null or content_db == null:
		_fail("Could not initialize required singletons for smoke validation.")
		return

	content_db.call("load_all")

	var run_controller_script: Script = load("res://scripts/gameplay/run_controller.gd")
	var run_controller: Node = run_controller_script.new()
	_track_node(run_controller)

	run_controller.call("start_run", DEBUG_SEED, DEBUG_CHARACTER_ID, DEBUG_MAP_ID)
	if not _assert_state(run_controller, RunController.RunStateType.ROOM, "ROOM"):
		return
	if not _assert_true(int(run_state.get("current_round")) == 1, "Expected current_round=1 after start_run."):
		return

	run_controller.call("continue_from_room")
	if not _assert_state(run_controller, RunController.RunStateType.BUILD_PHASE, "BUILD_PHASE"):
		return

	var round_def: Resource = run_controller.call("get_current_round_def")
	if not _assert_true(round_def != null, "Expected current RoundDef to resolve before wave start."):
		return

	run_controller.call("start_current_wave")
	if not _assert_state(run_controller, RunController.RunStateType.WAVE_RUNNING, "WAVE_RUNNING"):
		return

	var previous_gold: int = int(run_state.get("gold"))
	var expected_reward_gold: int = int(run_controller.call("get_round_reward_gold"))
	run_controller.call("handle_wave_completed")
	if not _assert_state(run_controller, RunController.RunStateType.REWARD_SELECTION, "REWARD_SELECTION"):
		return
	if not _assert_true(int(run_state.get("gold")) == previous_gold + expected_reward_gold, "Expected gold reward to be applied on wave completion."):
		return

	var reward_ids: Array[String] = _collect_reward_ids(content_db)
	if not _assert_true(reward_ids.size() > 0, "Expected at least one valid reward id in ContentDB."):
		return

	var picked_reward: String = reward_ids[0]
	run_controller.call("accept_reward", picked_reward)
	if not _assert_state(run_controller, RunController.RunStateType.ROOM, "ROOM"):
		return
	if not _assert_true(int(run_state.get("current_round")) == 2, "Expected current_round=2 after accepting reward."):
		return
	if not _assert_true((run_state.get("picked_item_ids") as Array[String]).has(picked_reward), "Expected picked reward to be stored in RunState."):
		return

	if not await _validate_runtime_persistence():
		return
	if not await _validate_defeat_flow():
		return

	await _cleanup_created_nodes()
	print("Flow smoke validation OK.")
	quit(0)

func _assert_state(controller: Node, expected: int, name: String) -> bool:
	var current_state: int = int(controller.get("current_state"))
	if current_state == expected:
		return true
	_fail("Expected state %s but got %d." % [name, current_state])
	return false

func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _ensure_singleton(node_name: String, script_path: String) -> Node:
	var existing: Node = get_root().get_node_or_null(node_name)
	if existing != null:
		return existing

	var script: Script = load(script_path)
	if script == null:
		return null
	var instance: Node = script.new()
	if instance == null:
		return null
	instance.name = node_name
	_track_node(instance)
	return instance

func _collect_reward_ids(content_db: Node) -> Array[String]:
	var ids: Array[String] = []
	var all_ids: Array[String] = []
	for key: Variant in content_db.get("items").keys():
		all_ids.append(String(key))
	all_ids.sort()
	for item_id: String in all_ids:
		if content_db.call("get_item", item_id) != null:
			ids.append(item_id)
	return ids

func _validate_runtime_persistence() -> bool:
	var boot_scene: PackedScene = load("res://scenes/boot/boot.tscn")
	if boot_scene == null:
		_fail("Could not load boot scene for lifecycle smoke validation.")
		return false

	var boot: Node = boot_scene.instantiate()
	if boot == null:
		_fail("Could not instantiate boot scene for lifecycle smoke validation.")
		return false
	get_root().add_child(boot)

	boot.call("_on_start_game_requested")
	await process_frame
	boot.call("_on_room_continue_requested")
	await process_frame

	var gameplay: Node = boot.get("_gameplay_screen")
	if not _assert_true(gameplay != null, "Expected gameplay runtime to exist in build phase."):
		return false
	var wave_controller: Node = gameplay.get("wave_controller")
	if wave_controller != null:
		wave_controller.set("use_async_timers", false)
	if not _assert_true(String(gameplay.call("get_phase_name")) == "BUILD_PHASE", "Expected gameplay phase to be Build Phase after Continue."):
		return false
	if not _assert_true(bool(gameplay.call("build_debug_first_pad")), "Expected to build one defense in build phase."):
		return false
	if not _assert_true(int(gameplay.call("get_defense_count")) == 1, "Expected defense count=1 after initial build."):
		return false
	if not _assert_true(bool(gameplay.call("select_first_defense_for_debug")), "Expected selecting first defense to succeed in build phase."):
		return false
	if not _assert_true(String(gameplay.call("get_selected_defense_id")) == "manguerazo", "Expected selected defense id to be manguerazo."):
		return false
	var gold_before_sell: int = int(_ensure_singleton("RunState", "res://autoload/run_state.gd").get("gold"))
	var refund: int = int(gameplay.call("sell_selected_for_debug"))
	if not _assert_true(refund == 44, "Expected round 1 sell refund to be 44 gold (80% of 55)."):
		return false
	if not _assert_true(int(_ensure_singleton("RunState", "res://autoload/run_state.gd").get("gold")) == gold_before_sell + refund, "Expected gold to increase by sell refund."):
		return false
	await process_frame
	if not _assert_true(int(gameplay.call("get_defense_count")) == 0, "Expected defense count=0 after selling selected defense."):
		return false
	if not _assert_true(bool(gameplay.call("build_debug_first_pad")), "Expected first pad to be buildable again after selling."):
		return false
	if not _assert_true(int(gameplay.call("get_defense_count")) == 1, "Expected defense rebuild after sell to succeed."):
		return false

	boot.call("_on_start_wave_requested")
	await process_frame
	var gameplay_after_wave_start: Node = boot.get("_gameplay_screen")
	if not _assert_true(gameplay_after_wave_start == gameplay, "Expected gameplay runtime instance to persist into wave phase."):
		return false
	if not _assert_true(String(gameplay_after_wave_start.call("get_phase_name")) == "WAVE_RUNNING", "Expected gameplay phase to be Wave Running after wave start."):
		return false
	if not _assert_true(int(gameplay_after_wave_start.call("get_defense_count")) == 1, "Expected defense to persist from build to wave."):
		return false
	if not _assert_true(bool(gameplay_after_wave_start.call("select_first_defense_for_debug")), "Expected selecting defense in wave phase to still work for UI/debug checks."):
		return false
	if not _assert_true(int(gameplay_after_wave_start.call("sell_selected_for_debug")) == 0, "Expected selling to be blocked during Wave Running."):
		return false

	boot.call("_on_force_complete_wave_requested")
	await process_frame
	boot.call("_on_reward_chosen", "botellin_congelado")
	await process_frame
	boot.call("_on_room_continue_requested")
	await process_frame

	var gameplay_next_round: Node = boot.get("_gameplay_screen")
	if not _assert_true(gameplay_next_round == gameplay, "Expected gameplay runtime instance to persist into next round build phase."):
		return false
	if not _assert_true(String(gameplay_next_round.call("get_phase_name")) == "BUILD_PHASE", "Expected gameplay phase to reset to Build Phase in next round."):
		return false
	if not _assert_true(int(gameplay_next_round.call("get_defense_count")) == 1, "Expected defense to persist across rounds in same run."):
		return false

	boot.queue_free()
	await process_frame
	return true

func _validate_defeat_flow() -> bool:
	var boot_scene: PackedScene = load("res://scenes/boot/boot.tscn")
	if boot_scene == null:
		_fail("Could not load boot scene for defeat flow validation.")
		return false

	var boot: Node = boot_scene.instantiate()
	if boot == null:
		_fail("Could not instantiate boot scene for defeat flow validation.")
		return false
	get_root().add_child(boot)

	boot.call("_on_start_game_requested")
	await process_frame
	boot.call("_on_core_depleted")
	await process_frame

	var run_controller: Node = boot.get("_run_controller")
	if not _assert_true(run_controller != null, "Expected run controller to exist during defeat flow validation."):
		return false
	if not _assert_true(int(run_controller.get("current_state")) == RunController.RunStateType.DEFEAT, "Expected DEFEAT state after core depletion."):
		return false

	var active_screen: Node = boot.get("_active_screen")
	if not _assert_true(active_screen != null, "Expected defeat screen to be active after core depletion."):
		return false
	if not _assert_true(active_screen is EndScreenController, "Expected active defeat screen controller to be EndScreenController."):
		return false
	if not _assert_true(is_instance_valid(boot), "Expected boot instance to remain alive after defeat transition."):
		return false

	boot.queue_free()
	await process_frame
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
	await process_frame
	await process_frame
