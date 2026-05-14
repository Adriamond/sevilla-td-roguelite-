extends SceneTree

const DEBUG_SEED: int = 424242
const DEBUG_CHARACTER_ID: String = "manue_el_encerrado"
const DEBUG_MAP_ID: String = "pino_montano_bloques_bulevar"

var _created_nodes: Array[Node] = []
var _exit_requested: bool = false

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
	if not _assert_true(int(run_state.get("total_rounds")) == int(run_controller.call("get_total_rounds")), "Expected run_state total_rounds to match run controller total rounds."):
		return
	if not _validate_room_interactions(run_controller, run_state):
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

	if not _validate_reward_effects():
		return
	if not _validate_boss_round_data():
		return
	if not await _validate_runtime_persistence():
		return
	if not await _validate_defeat_flow():
		return

	await _drain_frames(24)
	await _cleanup_created_nodes()
	print("Flow smoke validation OK.")
	_request_exit(0)

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
	_request_exit(1)

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

func _validate_reward_effects() -> bool:
	var content_db: Node = _ensure_singleton("ContentDB", "res://autoload/content_db.gd")
	var run_state: Node = _ensure_singleton("RunState", "res://autoload/run_state.gd")
	var run_controller_script: Script = load("res://scripts/gameplay/run_controller.gd")
	if run_controller_script == null:
		_fail("Could not load run_controller.gd for reward effect validation.")
		return false
	var run_controller: Node = run_controller_script.new()
	_track_node(run_controller)

	for reward_id: String in ["litrito", "media_bellota", "rasta"]:
		if not _assert_true(content_db.call("get_item", reward_id) != null, "Expected reward item '%s' to exist." % reward_id):
			return false

	run_controller.call("start_run", DEBUG_SEED, DEBUG_CHARACTER_ID, DEBUG_MAP_ID)
	run_controller.call("start_current_wave")
	run_controller.call("handle_wave_completed")
	if not _assert_state(run_controller, RunController.RunStateType.REWARD_SELECTION, "REWARD_SELECTION"):
		return false

	var base_gold: int = int(run_state.get("gold"))
	run_controller.call("accept_reward", "media_bellota")
	if not _assert_true(int(run_state.get("gold")) == base_gold + 30, "Expected media_bellota to grant +30 gold immediately."):
		return false

	run_controller.call("start_current_wave")
	run_controller.call("handle_wave_completed")
	if not _assert_state(run_controller, RunController.RunStateType.REWARD_SELECTION, "REWARD_SELECTION"):
		return false
	var base_core_hp: int = int(run_state.get("core_hp"))
	run_controller.call("accept_reward", "rasta")
	if not _assert_true(int(run_state.get("core_hp")) == base_core_hp + 10, "Expected rasta to grant +10 core HP immediately."):
		return false

	run_controller.call("start_current_wave")
	run_controller.call("handle_wave_completed")
	if not _assert_state(run_controller, RunController.RunStateType.REWARD_SELECTION, "REWARD_SELECTION"):
		return false
	var range_before: float = float(run_state.get("defense_range_multiplier"))
	var crit_before: float = float(run_state.get("global_crit_chance"))
	run_controller.call("accept_reward", "litrito")
	if not _assert_true(is_equal_approx(float(run_state.get("defense_range_multiplier")), range_before + 0.1), "Expected litrito to increase defense range multiplier by +0.10."):
		return false
	if not _assert_true(is_equal_approx(float(run_state.get("global_crit_chance")), min(0.5, crit_before + 0.1)), "Expected litrito to increase crit chance by +0.10 with cap 0.50."):
		return false

	run_state.set("global_crit_chance", 0.45)
	run_controller.call("start_current_wave")
	run_controller.call("handle_wave_completed")
	if not _assert_state(run_controller, RunController.RunStateType.REWARD_SELECTION, "REWARD_SELECTION"):
		return false
	run_controller.call("accept_reward", "litrito")
	if not _assert_true(is_equal_approx(float(run_state.get("global_crit_chance")), 0.5), "Expected litrito crit chance to cap at 0.50."):
		return false

	return true

func _validate_boss_round_data() -> bool:
	var content_db: Node = _ensure_singleton("ContentDB", "res://autoload/content_db.gd")
	var run_controller_script: Script = load("res://scripts/gameplay/run_controller.gd")
	if run_controller_script == null:
		_fail("Could not load run_controller.gd for boss round validation.")
		return false
	var run_controller: Node = run_controller_script.new()
	_track_node(run_controller)
	run_controller.call("start_run", DEBUG_SEED, DEBUG_CHARACTER_ID, DEBUG_MAP_ID)
	var run_state: Node = _ensure_singleton("RunState", "res://autoload/run_state.gd")
	run_state.set("current_round", 6)
	var boss_round_def: Resource = run_controller.call("get_current_round_def")
	if not _assert_true(boss_round_def != null, "Expected final round definition to resolve for round 6."):
		return false
	if not _assert_true(bool(boss_round_def.get("has_boss")), "Expected final round to be marked has_boss=true."):
		return false
	var boss_enemy_id: String = String(boss_round_def.get("boss_enemy_id"))
	if not _assert_true(not boss_enemy_id.is_empty(), "Expected final round boss_enemy_id to be set."):
		return false
	var boss_def: Resource = content_db.call("get_enemy", boss_enemy_id)
	if not _assert_true(boss_def != null, "Expected boss enemy definition to exist for final round."):
		return false
	if not _assert_true(bool(boss_def.get("is_boss")), "Expected final round boss enemy to be flagged is_boss=true."):
		return false
	return true

func _validate_runtime_persistence() -> bool:
	var boot_scene: PackedScene = load("res://scenes/boot/boot.tscn")
	if boot_scene == null:
		_fail("Could not load boot scene for lifecycle smoke validation.")
		return false

	var boot: Node = boot_scene.instantiate()
	if boot == null:
		_fail("Could not instantiate boot scene for lifecycle smoke validation.")
		return false
	_track_node(boot)

	boot.call("_on_start_game_requested")
	await process_frame
	var gameplay_in_room: Node = boot.get("_gameplay_screen")
	if not _assert_true(gameplay_in_room != null, "Expected gameplay runtime to exist behind Room screen."):
		return false
	if not _assert_true(not bool(gameplay_in_room.call("is_gameplay_presentation_visible")), "Expected gameplay presentation to be hidden while Room screen is displayed."):
		return false
	if not _validate_overlay_screen_space(boot, "Room"):
		return false

	boot.call("_on_room_continue_requested")
	await process_frame

	var gameplay: Node = boot.get("_gameplay_screen")
	if not _assert_true(gameplay != null, "Expected gameplay runtime to exist in build phase."):
		return false
	if not _assert_true(bool(gameplay.call("is_gameplay_presentation_visible")), "Expected gameplay presentation to be visible in Build Phase."):
		return false
	var run_state: Node = _ensure_singleton("RunState", "res://autoload/run_state.gd")
	run_state.set("gold", 400)
	run_state.get("gold_changed").emit(int(run_state.get("gold")))
	var content_db: Node = _ensure_singleton("ContentDB", "res://autoload/content_db.gd")
	var manguerazo_def: Resource = content_db.call("get_defense", "manguerazo")
	var cable_def: Resource = content_db.call("get_defense", "cable_pelao")
	if not _assert_true(manguerazo_def != null and cable_def != null, "Expected manguerazo and cable_pelao defs to exist for flow smoke validation."):
		return false
	var manguerazo_base_cost: int = int(manguerazo_def.get("base_cost"))
	var cable_base_cost: int = int(cable_def.get("base_cost"))
	var manguerazo_total_invested: int = manguerazo_base_cost + 45
	var manguerazo_round_2_refund: int = int(floor(float(manguerazo_total_invested) * 0.8))
	var wave_controller: Node = gameplay.get("wave_controller")
	if wave_controller != null:
		wave_controller.set("use_async_timers", false)
	if not _assert_true(String(gameplay.call("get_phase_name")) == "BUILD_PHASE", "Expected gameplay phase to be Build Phase after Continue."):
		return false
	if not _assert_true(int(gameplay.call("get_total_rounds")) == 6, "Expected gameplay controller to expose total rounds=6 in MVP."):
		return false
	if not _validate_bigmap_camera_workflow(gameplay):
		return false
	if not _assert_true(bool(gameplay.call("build_debug_first_pad_with", "manguerazo")), "Expected to build first manguerazo in build phase."):
		return false
	if not _assert_true(bool(gameplay.call("build_debug_first_pad_with", "manguerazo")), "Expected to build second manguerazo in build phase."):
		return false
	if not _assert_true(bool(gameplay.call("select_defense_by_id_at_index_for_debug", "manguerazo", 0)), "Expected selecting first manguerazo to succeed for per-defense upgrade test."):
		return false
	if not _assert_true(bool(gameplay.call("upgrade_selected_for_debug")), "Expected first manguerazo upgrade to succeed."):
		return false
	if not _assert_true(bool(gameplay.call("select_defense_by_id_at_index_for_debug", "manguerazo", 1)), "Expected selecting second manguerazo to succeed for per-defense upgrade test."):
		return false
	if not _assert_true(int(gameplay.call("get_selected_level")) == 1, "Expected second manguerazo to remain level 1 before its own upgrade."):
		return false
	if not _assert_true(bool(gameplay.call("upgrade_selected_for_debug")), "Expected second manguerazo upgrade to succeed independently."):
		return false
	if not _assert_true(bool(gameplay.call("select_defense_by_id_at_index_for_debug", "manguerazo", 0)), "Expected selecting first manguerazo again to verify final level."):
		return false
	if not _assert_true(int(gameplay.call("get_selected_level")) == 2, "Expected first manguerazo to remain level 2."):
		return false
	if not _assert_true(bool(gameplay.call("select_defense_by_id_at_index_for_debug", "manguerazo", 1)), "Expected selecting second manguerazo again to verify final level."):
		return false
	if not _assert_true(int(gameplay.call("get_selected_level")) == 2, "Expected second manguerazo to reach level 2."):
		return false
	if not _assert_true(int(gameplay.call("get_defense_count")) == 2, "Expected defense count=2 after building two manguerazos."):
		return false
	if not _assert_true(bool(gameplay.call("build_debug_first_pad_with", "cable_pelao")), "Expected to build cable_pelao in build phase."):
		return false
	if not _assert_true(int(gameplay.call("get_defense_count")) == 3, "Expected defense count=3 after adding cable_pelao."):
		return false
	if not _assert_true(bool(gameplay.call("select_defense_by_id_for_debug", "cable_pelao")), "Expected selecting cable_pelao to succeed in build phase for baseline stat checks."):
		return false
	if not _assert_true(String(gameplay.call("get_selected_defense_id")) == "cable_pelao", "Expected selected defense id to be cable_pelao."):
		return false
	if not _assert_true(int(gameplay.call("get_selected_level")) == 1, "Expected initial selected defense level to be 1."):
		return false
	var level_1_damage: float = float(gameplay.call("get_selected_damage"))
	if not _assert_true(level_1_damage > 0.0, "Expected positive level 1 selected defense damage."):
		return false
	if not _assert_true(int(gameplay.call("get_selected_upgrade_cost")) == 45, "Expected selected upgrade cost to be 45 at level 1."):
		return false
	var manguerazo_range_before_litrito: float = float(gameplay.call("get_selected_range"))
	if not _assert_true(bool(gameplay.call("select_defense_by_id_for_debug", "cable_pelao")), "Expected selecting cable_pelao to succeed before gold rebalance."):
		return false
	if not _assert_true(String(gameplay.call("get_selected_defense_id")) == "cable_pelao", "Expected selected defense id to switch to cable_pelao."):
		return false
	var cable_damage: float = float(gameplay.call("get_selected_damage"))
	if not _assert_true(cable_damage > 0.0, "Expected cable_pelao selected damage to be positive."):
		return false
	var cable_pre_upgrade_refund: int = int(gameplay.call("sell_selected_for_debug"))
	if not _assert_true(cable_pre_upgrade_refund == cable_base_cost, "Expected pre-wave cable_pelao sell refund to be 100% of base cost."):
		return false
	await process_frame
	if not _assert_true(bool(gameplay.call("select_defense_by_id_for_debug", "manguerazo")), "Expected selecting manguerazo again to upgrade after cable sell."):
		return false
	var level_2_damage: float = float(gameplay.call("get_selected_damage"))
	if not _assert_true(level_2_damage >= level_1_damage, "Expected selected defense damage sanity after per-defense upgrades."):
		return false
	if not _assert_true(int(gameplay.call("get_selected_upgrade_cost")) == 0, "Expected no further upgrade cost at max level."):
		return false
	if not _assert_true(String(gameplay.call("get_selected_defense_id")) == "manguerazo", "Expected selected defense to remain manguerazo after upgrade refresh."):
		return false
	if not _assert_true(int(gameplay.call("get_selected_level")) == 2, "Expected selected panel to show level 2 after upgrade."):
		return false
	if not _assert_true(is_equal_approx(float(gameplay.call("get_selected_damage")), level_2_damage), "Expected selected panel to show upgraded damage after upgrade."):
		return false
	if not _assert_true(not bool(gameplay.call("upgrade_selected_for_debug")), "Expected additional upgrade attempt to fail at max level."):
		return false
	var gold_before_sell: int = int(_ensure_singleton("RunState", "res://autoload/run_state.gd").get("gold"))
	var defense_count_before_sell: int = int(gameplay.call("get_defense_count"))
	var refund: int = int(gameplay.call("sell_selected_for_debug"))
	if not _assert_true(refund == manguerazo_total_invested, "Expected pre-wave upgraded manguerazo sell refund to be 100% of total invested cost."):
		return false
	if not _assert_true(int(_ensure_singleton("RunState", "res://autoload/run_state.gd").get("gold")) == gold_before_sell + refund, "Expected gold to increase by sell refund."):
		return false
	await process_frame
	if not _assert_true(int(gameplay.call("get_defense_count")) == defense_count_before_sell - 1, "Expected defense count to decrease by one after selling selected manguerazo."):
		return false
	if not _assert_true(bool(gameplay.call("build_debug_first_pad_with", "manguerazo")), "Expected pad to be buildable again for manguerazo after selling."):
		return false
	if not _assert_true(int(gameplay.call("get_defense_count")) == defense_count_before_sell, "Expected defense rebuild for manguerazo after selling to restore defense count."):
		return false
	if not _assert_true(bool(gameplay.call("select_defense_by_id_for_debug", "manguerazo")), "Expected selecting rebuilt manguerazo to succeed before wave start."):
		return false

	boot.call("_on_start_wave_requested")
	await process_frame
	var gameplay_after_wave_start: Node = boot.get("_gameplay_screen")
	if not _assert_true(gameplay_after_wave_start == gameplay, "Expected gameplay runtime instance to persist into wave phase."):
		return false
	if not _assert_true(String(gameplay_after_wave_start.call("get_phase_name")) == "WAVE_RUNNING", "Expected gameplay phase to be Wave Running after wave start."):
		return false
	if not _assert_true(int(gameplay_after_wave_start.call("get_defense_count")) >= 1, "Expected built defenses to persist from build to wave."):
		return false
	if not _assert_true(bool(gameplay_after_wave_start.call("select_defense_by_id_for_debug", "manguerazo")), "Expected selecting manguerazo in wave phase to still work for UI/debug checks."):
		return false
	var run_state_wave: Node = _ensure_singleton("RunState", "res://autoload/run_state.gd")
	var active_enemies: Array = wave_controller.call("get_active_enemies")
	if not _assert_true(active_enemies.size() > 0, "Expected active enemies to exist for kill gold validation."):
		return false
	var kill_target: Node = active_enemies[0] as Node
	if not _assert_true(kill_target != null, "Expected a valid enemy node for kill gold validation."):
		return false
	var kill_enemy_id: String = String(kill_target.get("enemy_id"))
	var kill_def: Resource = content_db.call("get_enemy", kill_enemy_id)
	if not _assert_true(kill_def != null, "Expected kill target enemy def to resolve for gold reward validation."):
		return false
	var expected_kill_gold: int = int(kill_def.get("gold_reward"))
	var gold_before_kill: int = int(run_state_wave.get("gold"))
	kill_target.call("apply_damage", 99999.0, false)
	var gold_after_first_kill: int = int(run_state_wave.get("gold"))
	if not _assert_true(gold_after_first_kill == gold_before_kill + expected_kill_gold, "Expected kill gold reward to be applied exactly once on enemy death."):
		return false
	kill_target.call("apply_damage", 99999.0, false)
	if not _assert_true(int(run_state_wave.get("gold")) == gold_after_first_kill, "Expected no duplicate kill gold on repeated damage calls after death."):
		return false
	var active_enemies_after_kill: Array = wave_controller.call("get_active_enemies")
	if active_enemies_after_kill.size() > 0:
		var leak_target: Node = active_enemies_after_kill[0] as Node
		if leak_target != null:
			var gold_before_leak_signal: int = int(run_state_wave.get("gold"))
			leak_target.emit_signal("reached_end", String(leak_target.get("enemy_id")), int(leak_target.get("leak_damage")))
			if not _assert_true(int(run_state_wave.get("gold")) == gold_before_leak_signal, "Expected leaked enemies to not grant kill gold."):
				return false
	if not _assert_true(not bool(gameplay_after_wave_start.call("upgrade_selected_for_debug")), "Expected upgrading to be blocked during Wave Running."):
		return false
	if not _assert_true(int(gameplay_after_wave_start.call("sell_selected_for_debug")) == 0, "Expected selling to be blocked during Wave Running."):
		return false

	boot.call("_on_force_complete_wave_requested")
	await process_frame
	if not _validate_overlay_screen_space(boot, "Reward"):
		return false
	boot.call("_on_reward_chosen", "litrito")
	await process_frame
	if not _assert_true(not bool(gameplay.call("is_gameplay_presentation_visible")), "Expected gameplay presentation to be hidden after reward returns to Room."):
		return false
	boot.call("_on_room_continue_requested")
	await process_frame

	var gameplay_next_round: Node = boot.get("_gameplay_screen")
	if not _assert_true(gameplay_next_round == gameplay, "Expected gameplay runtime instance to persist into next round build phase."):
		return false
	if not _assert_true(bool(gameplay_next_round.call("is_gameplay_presentation_visible")), "Expected gameplay presentation to be visible after Room Continue into next Build Phase."):
		return false
	if not _assert_true(String(gameplay_next_round.call("get_phase_name")) == "BUILD_PHASE", "Expected gameplay phase to reset to Build Phase in next round."):
		return false
	if not _assert_true(int(gameplay_next_round.call("get_defense_count")) >= 1, "Expected defenses to persist across rounds in same run."):
		return false
	if not _assert_true(bool(gameplay_next_round.call("select_defense_by_id_for_debug", "manguerazo")), "Expected selecting persisted manguerazo in next build phase to succeed."):
		return false
	if not _assert_true(is_equal_approx(float(gameplay_next_round.call("get_run_range_multiplier")), 1.1), "Expected litrito reward to set run defense range multiplier to 1.1."):
		return false
	if not _assert_true(is_equal_approx(float(gameplay_next_round.call("get_run_crit_chance")), 0.1), "Expected litrito reward to set global crit chance to 0.1."):
		return false
	var manguerazo_range_after_litrito: float = float(gameplay_next_round.call("get_selected_range"))
	if not _assert_true(manguerazo_range_after_litrito > manguerazo_range_before_litrito, "Expected effective defense range to increase after litrito reward."):
		return false
	if not _assert_true(int(gameplay_next_round.call("get_selected_level")) == 2, "Expected upgraded defense level to persist into next round build phase."):
		return false
	if not _assert_true(int(gameplay_next_round.call("get_selected_refund_amount")) == manguerazo_round_2_refund, "Expected post-wave refund to follow total-invested formula (80% on round 2)."):
		return false
	var gold_before_post_wave_sell: int = int(_ensure_singleton("RunState", "res://autoload/run_state.gd").get("gold"))
	var post_wave_refund: int = int(gameplay_next_round.call("sell_selected_for_debug"))
	if not _assert_true(post_wave_refund == manguerazo_round_2_refund, "Expected sell refund after one participated wave to use the round 2 formula."):
		return false
	if not _assert_true(int(_ensure_singleton("RunState", "res://autoload/run_state.gd").get("gold")) == gold_before_post_wave_sell + post_wave_refund, "Expected gold to increase by post-wave refund amount."):
		return false
	boot.queue_free()
	await process_frame
	await process_frame
	return true

func _validate_bigmap_camera_workflow(gameplay: Node) -> bool:
	if gameplay == null:
		_fail("Expected gameplay root for big-map camera smoke validation.")
		return false
	if not gameplay.has_method("ensure_map_loaded_for_debug"):
		_fail("Gameplay root missing map-load debug API for big-map camera smoke validation.")
		return false
	if not bool(gameplay.call("ensure_map_loaded_for_debug")):
		_fail("Gameplay root could not load map for big-map camera smoke validation.")
		return false
	if not gameplay.has_method("get_camera_navigation_debug_state") \
		or not gameplay.has_method("set_camera_zoom_for_debug") \
		or not gameplay.has_method("move_camera_for_debug"):
		_fail("Gameplay root missing camera navigation debug API for big-map camera smoke validation.")
		return false

	var state: Dictionary = gameplay.call("get_camera_navigation_debug_state")
	if not _assert_true(bool(state.get("camera_exists", false)), "Expected gameplay camera to exist for big-map smoke validation."):
		return false
	if not _assert_true(bool(state.get("camera_enabled", false)), "Expected gameplay camera to be current/enabled for big-map smoke validation."):
		return false

	var min_zoom: float = float(state.get("min_zoom", 0.0))
	var max_zoom: float = float(state.get("max_zoom", 0.0))
	if not _assert_true(min_zoom > 0.0 and max_zoom > min_zoom, "Expected sane camera zoom bounds for big-map smoke validation."):
		return false

	var map_bounds: Rect2 = state.get("map_world_bounds", Rect2())
	if not _assert_true(_rect_has_valid_size(map_bounds), "Expected valid map world bounds for big-map smoke validation."):
		return false
	var clamp_bounds: Rect2 = state.get("clamp_bounds", Rect2())
	if not _assert_true(_rect_has_valid_size(clamp_bounds), "Expected valid camera clamp bounds for big-map smoke validation."):
		return false
	if not _assert_true(_rect_contains_rect(clamp_bounds, map_bounds), "Expected camera clamp bounds to contain map world bounds."):
		return false
	var safe_screen_rect: Rect2 = state.get("safe_screen_rect", Rect2())
	if not _assert_true(_rect_has_valid_size(safe_screen_rect), "Expected valid camera safe screen rect for big-map smoke validation."):
		return false
	var safe_world_rect: Rect2 = state.get("safe_world_rect", Rect2())
	if not _assert_true(_rect_has_valid_size(safe_world_rect), "Expected valid camera safe world rect before pan/zoom."):
		return false

	gameplay.call("set_camera_zoom_for_debug", max_zoom * 10.0)
	state = gameplay.call("get_camera_navigation_debug_state")
	if not _assert_true(float(state.get("current_zoom", 0.0)) <= max_zoom + 0.001, "Expected debug camera zoom to clamp at max."):
		return false
	if not _assert_true(_camera_state_is_finite(state), "Expected finite camera state after max zoom clamp."):
		return false

	gameplay.call("set_camera_zoom_for_debug", min_zoom * 0.1)
	state = gameplay.call("get_camera_navigation_debug_state")
	if not _assert_true(float(state.get("current_zoom", 0.0)) >= min_zoom - 0.001, "Expected debug camera zoom to clamp at min."):
		return false
	if not _assert_true(_camera_state_is_finite(state), "Expected finite camera state after min zoom clamp."):
		return false

	gameplay.call("set_camera_zoom_for_debug", 1.15)
	gameplay.call("move_camera_for_debug", Vector2(100000.0, 100000.0))
	state = gameplay.call("get_camera_navigation_debug_state")
	if not _assert_true(_camera_state_is_finite(state), "Expected finite camera state after positive debug pan."):
		return false
	if not _assert_true(_rect_contains_rect(state.get("clamp_bounds", Rect2()), state.get("safe_world_rect", Rect2())), "Expected safe world rect to stay inside clamp bounds after positive debug pan."):
		return false

	gameplay.call("move_camera_for_debug", Vector2(-200000.0, -200000.0))
	state = gameplay.call("get_camera_navigation_debug_state")
	if not _assert_true(_camera_state_is_finite(state), "Expected finite camera state after negative debug pan."):
		return false
	if not _assert_true(_rect_contains_rect(state.get("clamp_bounds", Rect2()), state.get("safe_world_rect", Rect2())), "Expected safe world rect to stay inside clamp bounds after negative debug pan."):
		return false

	return true

func _validate_overlay_screen_space(boot: Node, expected_screen_name: String) -> bool:
	if boot == null:
		_fail("Expected boot node for %s overlay screen-space validation." % expected_screen_name)
		return false
	var overlay_layer: Node = boot.get("_overlay_layer") as Node
	var overlay_screen: Node = boot.get("_overlay_screen") as Node
	if not _assert_true(overlay_layer != null, "Expected %s overlay layer to exist." % expected_screen_name):
		return false
	if not _assert_true(overlay_layer is CanvasLayer, "Expected %s overlay layer to be a CanvasLayer." % expected_screen_name):
		return false
	if not _assert_true(overlay_screen != null, "Expected %s overlay screen to exist." % expected_screen_name):
		return false
	if not _assert_true(overlay_screen.get_parent() == overlay_layer, "Expected %s overlay screen to be parented under overlay CanvasLayer." % expected_screen_name):
		return false
	var gameplay: Node = boot.get("_gameplay_screen") as Node
	if gameplay != null:
		if not _assert_true(not gameplay.is_ancestor_of(overlay_screen), "Expected %s overlay to not be parented under moving gameplay world." % expected_screen_name):
			return false
	if overlay_screen is Control:
		var screen_rect: Rect2 = (overlay_screen as Control).get_global_rect()
		if not _assert_true(_rect_has_valid_size(screen_rect), "Expected %s overlay Control rect to have valid size." % expected_screen_name):
			return false
	return true

func _camera_state_is_finite(state: Dictionary) -> bool:
	var position: Vector2 = state.get("camera_position", Vector2.ZERO)
	var safe_world_rect: Rect2 = state.get("safe_world_rect", Rect2())
	var clamp_bounds: Rect2 = state.get("clamp_bounds", Rect2())
	return _vector_is_finite(position) \
		and _float_is_finite(float(state.get("current_zoom", 0.0))) \
		and _rect_is_finite(safe_world_rect) \
		and _rect_is_finite(clamp_bounds)

func _rect_contains_rect(outer: Rect2, inner: Rect2) -> bool:
	if not _rect_has_valid_size(outer) or not _rect_has_valid_size(inner):
		return false
	return inner.position.x >= outer.position.x - 0.5 \
		and inner.position.y >= outer.position.y - 0.5 \
		and inner.end.x <= outer.end.x + 0.5 \
		and inner.end.y <= outer.end.y + 0.5

func _rect_has_valid_size(rect: Rect2) -> bool:
	return _rect_is_finite(rect) and rect.size.x > 0.0 and rect.size.y > 0.0

func _rect_is_finite(rect: Rect2) -> bool:
	return _vector_is_finite(rect.position) and _vector_is_finite(rect.size)

func _vector_is_finite(value: Vector2) -> bool:
	return _float_is_finite(value.x) and _float_is_finite(value.y)

func _float_is_finite(value: float) -> bool:
	return value == value and absf(value) < INF

func _validate_room_interactions(run_controller: Node, run_state: Node) -> bool:
	var base_core_hp: int = int(run_state.get("core_hp"))
	var madre_result: Dictionary = run_controller.call("use_room_interaction", "llamar_madre")
	if not _assert_true(bool(madre_result.get("ok", false)), "Expected llamar_madre room interaction to succeed."):
		return false
	if not _assert_true(int(run_state.get("core_hp")) == base_core_hp + 5, "Expected llamar_madre to grant +5 Core HP."):
		return false
	var madre_repeat: Dictionary = run_controller.call("use_room_interaction", "llamar_madre")
	if not _assert_true(not bool(madre_repeat.get("ok", false)), "Expected llamar_madre to be limited to one use per run."):
		return false
	if not _assert_true(int(run_state.get("core_hp")) == base_core_hp + 5, "Expected llamar_madre duplicate use to not heal again."):
		return false

	var base_gold: int = int(run_state.get("gold"))
	var coins_result: Dictionary = run_controller.call("use_room_interaction", "buscar_monedas_pantalon")
	if not _assert_true(bool(coins_result.get("ok", false)), "Expected buscar_monedas_pantalon room interaction to succeed."):
		return false
	if not _assert_true(int(run_state.get("gold")) == base_gold + 25, "Expected buscar_monedas_pantalon to grant +25 gold."):
		return false
	var coins_repeat: Dictionary = run_controller.call("use_room_interaction", "buscar_monedas_pantalon")
	if not _assert_true(not bool(coins_repeat.get("ok", false)), "Expected buscar_monedas_pantalon to be limited to one use per run."):
		return false
	if not _assert_true(int(run_state.get("gold")) == base_gold + 25, "Expected buscar_monedas_pantalon duplicate use to not grant gold again."):
		return false

	var router_result: Dictionary = run_controller.call("use_room_interaction", "reiniciar_router")
	if not _assert_true(bool(router_result.get("ok", false)), "Expected reiniciar_router room interaction to succeed."):
		return false
	if not _assert_true(is_equal_approx(float(run_state.get("pending_next_wave_crit_bonus")), 0.1), "Expected reiniciar_router to set pending next-wave crit bonus."):
		return false

	run_controller.call("start_run", DEBUG_SEED + 1, DEBUG_CHARACTER_ID, DEBUG_MAP_ID)
	if not _assert_true(not bool(run_state.call("has_used_room_interaction", "llamar_madre")), "Expected room interaction use state to reset on new run."):
		return false
	if not _assert_true(is_equal_approx(float(run_state.get("pending_next_wave_crit_bonus")), 0.0), "Expected pending router crit bonus to reset on new run."):
		return false
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
	_track_node(boot)

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
	_created_nodes.clear()
	await process_frame
	await process_frame
	await process_frame
	await _drain_frames(24)

func _request_exit(code: int) -> void:
	if _exit_requested:
		return
	_exit_requested = true
	call_deferred("_exit_after_cleanup", code)

func _exit_after_cleanup(code: int) -> void:
	await _cleanup_created_nodes()
	quit(code)

func _drain_frames(frame_count: int) -> void:
	for i: int in range(max(frame_count, 0)):
		await process_frame
