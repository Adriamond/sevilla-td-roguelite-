extends SceneTree

const DEBUG_SEED: int = 424242
const DEBUG_CHARACTER_ID: String = "manue_el_encerrado"
const DEBUG_MAP_ID: String = "pino_montano_bloques_bulevar"

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
	get_root().add_child(run_controller)

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
	get_root().add_child(instance)
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
