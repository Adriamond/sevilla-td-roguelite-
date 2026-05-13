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
@onready var gold_label: Label = %GoldValueLabel
@onready var active_enemies_label: Label = %ActiveEnemiesValueLabel
@onready var spawned_enemies_label: Label = %SpawnedEnemiesValueLabel
@onready var leaked_enemies_label: Label = %LeakedEnemiesValueLabel
@onready var build_selection_label: Label = %BuildSelectionValueLabel
@onready var select_manguerazo_button: Button = %SelectManguerazoButton
@onready var select_cable_pelao_button: Button = %SelectCablePelaoButton
@onready var build_hint_label: Label = %BuildHintLabel
@onready var selected_defense_label: Label = %SelectedDefenseValueLabel
@onready var selected_level_label: Label = %SelectedLevelValueLabel
@onready var selected_damage_label: Label = %SelectedDamageValueLabel
@onready var selected_range_label: Label = %SelectedRangeValueLabel
@onready var selected_fire_rate_label: Label = %SelectedFireRateValueLabel
@onready var upgrade_cost_label: Label = %UpgradeCostValueLabel
@onready var sell_refund_label: Label = %SellRefundValueLabel
@onready var upgrade_button: Button = %UpgradeDefenseButton
@onready var sell_button: Button = %SellDefenseButton
@onready var top_bar: Control = $UILayer/TopBar
@onready var top_bar_content: Control = $UILayer/TopBar/HBoxContainer
@onready var left_panel: Control = $UILayer/LeftPanel
@onready var left_panel_content: Control = $UILayer/LeftPanel/VBoxContainer
@onready var right_panel: Control = $UILayer/RightPanel
@onready var right_panel_content: Control = $UILayer/RightPanel/VBoxContainer
@onready var map_container: Node2D = %MapContainer
@onready var enemy_layer: Node2D = %EnemyLayer
@onready var defense_layer: Node2D = %DefenseLayer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var path_controller: PathController = %PathController
@onready var spawn_controller: SpawnController = %SpawnController
@onready var wave_controller: WaveController = %WaveController
@onready var defense_controller: DefenseController = %DefenseController

var _is_wave_running: bool = false
var _phase_name: String = "BUILD_PHASE"
var _map_instance: Node2D = null
var _active_round_def: Resource = null
var _spawned_count: int = 0
var _leaked_count: int = 0
var _build_defense_id: String = "manguerazo"
var _core_depleted_emitted: bool = false
var _layout_viewport_override: Vector2 = Vector2.ZERO
const DESIGN_VIEWPORT_SIZE: Vector2 = Vector2(1600.0, 900.0)
const MAP_DESIGN_SIZE: Vector2 = Vector2(960.0, 540.0)
const OUTER_MARGIN: float = 24.0
const PANEL_GAP: float = 24.0
const TOP_BAR_Y: float = 16.0
const TOP_BAR_HEIGHT: float = 44.0
const SIDE_PANEL_Y: float = 72.0
const SIDE_PANEL_BOTTOM_MARGIN: float = 44.0
const LEFT_PANEL_WIDTH: float = 240.0
const RIGHT_PANEL_WIDTH: float = 260.0
const PANEL_INSET: float = 12.0
const BOARD_TOP: float = 96.0
const BOARD_BOTTOM_MARGIN: float = 32.0
const BOARD_TOP_PADDING: float = 20.0

func show_build_phase() -> void:
	_is_wave_running = false
	_phase_name = "BUILD_PHASE"
	end_wave_cleanup()
	phase_label.text = "Build Phase"
	action_button.text = "Start Wave"
	action_button.disabled = false
	force_complete_button.visible = false
	force_complete_button.disabled = true
	select_manguerazo_button.disabled = false
	select_cable_pelao_button.disabled = false
	upgrade_button.disabled = not defense_controller.can_upgrade_selected_defense()
	sell_button.disabled = not defense_controller.can_sell_selected_defense()
	_set_build_pads_enabled(true)
	build_hint_label.text = "Click pad to build manguerazo"
	_update_status_labels()

func show_wave_running() -> void:
	_is_wave_running = true
	_phase_name = "WAVE_RUNNING"
	phase_label.text = "Wave Running"
	action_button.text = "Wave Running..."
	action_button.disabled = true
	force_complete_button.visible = true
	force_complete_button.disabled = false
	select_manguerazo_button.disabled = true
	select_cable_pelao_button.disabled = true
	upgrade_button.disabled = true
	sell_button.disabled = true
	_set_build_pads_enabled(false)
	build_hint_label.text = "Build disabled during wave"
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
	prepare_for_round(round_def)

func prepare_for_round(round_def: Resource) -> void:
	_active_round_def = round_def
	_ensure_map_loaded()
	_update_status_labels()

func start_wave() -> void:
	if _active_round_def == null:
		build_hint_label.text = "Cannot start wave: missing round data"
		show_build_phase()
		return
	_ensure_map_loaded()
	if path_controller.get_path_node("main") == null:
		build_hint_label.text = "Cannot start wave: path not ready"
		show_build_phase()
		return
	_spawned_count = 0
	_leaked_count = 0
	_core_depleted_emitted = false
	_clear_enemy_layer()
	var started: bool = wave_controller.start_round(_active_round_def)
	if not started:
		build_hint_label.text = "Cannot start wave: controller rejected start"
		show_build_phase()
		return
	defense_controller.mark_active_defenses_participated()
	show_wave_running()

func force_complete_wave() -> void:
	if not _is_wave_running or not wave_controller.is_running():
		return
	var completed: bool = wave_controller.debug_force_complete()
	if not completed:
		build_hint_label.text = "Force complete unavailable"

func end_wave_cleanup() -> void:
	_clear_enemy_layer()

func set_interactive_build_enabled(enabled: bool) -> void:
	_set_build_pads_enabled(enabled)
	if enabled:
		build_hint_label.text = "Click pad to build manguerazo"
		return
	build_hint_label.text = "Build disabled during wave"

func set_gameplay_presentation_visible(value: bool) -> void:
	visible = value
	if ui_layer != null:
		ui_layer.visible = value

func is_gameplay_presentation_visible() -> bool:
	if ui_layer == null:
		return visible
	return visible and ui_layer.visible

func reset_run_runtime() -> void:
	_is_wave_running = false
	_phase_name = "BUILD_PHASE"
	_spawned_count = 0
	_leaked_count = 0
	_active_round_def = null
	_core_depleted_emitted = false
	_clear_enemy_layer()
	_clear_defense_layer()
	if defense_controller != null:
		defense_controller.reset_run_runtime()
	_build_defense_id = "manguerazo"
	build_selection_label.text = _build_defense_id
	_set_build_pads_enabled(false)
	_update_status_labels()

func get_defense_count() -> int:
	if defense_layer == null:
		return 0
	return defense_layer.get_child_count()

func build_debug_first_pad() -> bool:
	if _map_instance == null:
		_ensure_map_loaded()
	if _map_instance == null:
		return false
	var pads_root: Node = _map_instance.get_node_or_null("BuildPads")
	if pads_root == null:
		return false
	for child: Node in pads_root.get_children():
		var pad: Area2D = child as Area2D
		if pad == null:
			continue
		var built: bool = defense_controller.build_defense(_build_defense_id, pad, String(pad.get("pad_category")))
		if built:
			_update_status_labels()
			return true
	return false

func _ready() -> void:
	spawn_controller.configure(enemy_layer, path_controller)
	wave_controller.configure(spawn_controller)
	defense_controller.configure(defense_layer, wave_controller)
	wave_controller.wave_completed.connect(_on_wave_completed)
	wave_controller.enemy_leaked.connect(_on_enemy_leaked)
	wave_controller.enemy_killed.connect(_on_enemy_killed)
	wave_controller.enemy_spawned.connect(_on_enemy_spawned)
	wave_controller.active_enemy_count_changed.connect(_on_active_enemy_count_changed)
	defense_controller.build_failed.connect(_on_build_failed)
	defense_controller.defense_selected.connect(_on_defense_selected)
	defense_controller.defense_sold.connect(_on_defense_sold)
	defense_controller.defense_upgraded.connect(_on_defense_upgraded)
	defense_controller.upgrade_failed.connect(_on_upgrade_failed)
	var run_state: Node = get_node("/root/RunState")
	run_state.gold_changed.connect(_on_run_gold_changed)
	run_state.core_hp_changed.connect(_on_run_core_hp_changed)
	run_state.round_changed.connect(_on_run_round_changed)
	var viewport: Viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	_apply_gameplay_layout()
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

	_apply_board_layout()
	map_container.add_child(_map_instance)
	_connect_build_pads()
	path_controller.clear_paths()
	var main_path: Path2D = _map_instance.get_node_or_null("MainPath")
	if main_path != null:
		path_controller.register_path("main", main_path)

func _center_camera() -> void:
	var camera: Camera2D = get_node_or_null("MainCamera")
	if camera == null:
		return
	camera.position = _get_layout_viewport_size() * 0.5

func _on_wave_completed(_round_index: int) -> void:
	_is_wave_running = false
	_phase_name = "BUILD_PHASE"
	end_wave_cleanup()
	wave_completed.emit()

func _on_enemy_leaked(_enemy_id: String, leak_damage: int) -> void:
	_leaked_count += 1
	var run_state: Node = get_node("/root/RunState")
	run_state.call("damage_core", leak_damage)
	_update_status_labels()
	if bool(run_state.call("is_defeated")) and not _core_depleted_emitted:
		_core_depleted_emitted = true
		core_depleted.emit()

func _on_enemy_spawned(_enemy_id: String) -> void:
	_spawned_count += 1
	_update_status_labels()

func _on_enemy_killed(_enemy_id: String, gold_awarded: int, _world_position: Vector2) -> void:
	if gold_awarded > 0:
		build_hint_label.text = "+%dg por kill" % gold_awarded
	_update_status_labels()

func _on_active_enemy_count_changed(_value: int) -> void:
	_update_status_labels()

func _on_run_gold_changed(_value: int) -> void:
	_update_status_labels()

func _on_run_core_hp_changed(_value: int) -> void:
	_update_status_labels()

func _on_run_round_changed(_value: int) -> void:
	_update_status_labels()

func _on_pad_clicked(pad: Area2D) -> void:
	if _is_wave_running:
		build_hint_label.text = "Cannot build while wave is running"
		return
	if pad == null:
		return

	var pad_category: String = String(pad.get("pad_category"))
	var pad_id: String = String(pad.get("pad_id"))
	var built: bool = defense_controller.build_defense(_build_defense_id, pad, pad_category)
	if built:
		build_hint_label.text = "Built %s on %s" % [_build_defense_id, pad_id]
		var latest_defense: DefenseActor = defense_layer.get_child(defense_layer.get_child_count() - 1) as DefenseActor
		if latest_defense != null:
			defense_controller.select_defense(latest_defense)
		_update_status_labels()

func _on_build_failed(reason: String) -> void:
	match reason:
		"not_enough_gold":
			build_hint_label.text = "Not enough gold"
		"cannot_build":
			build_hint_label.text = "Pad occupied or invalid"
		_:
			build_hint_label.text = "Build failed: %s" % reason

func _on_defense_selected(_defense: DefenseActor, _refund_amount: int) -> void:
	_update_status_labels()

func _on_defense_sold(defense_id: String, refund_amount: int) -> void:
	build_hint_label.text = "Sold %s for %d gold" % [defense_id, refund_amount]
	_update_status_labels()

func _on_defense_upgraded(defense_id: String, level: int, cost: int) -> void:
	build_hint_label.text = "Upgraded %s to Lv%d (-%d gold)" % [defense_id, level, cost]
	_update_status_labels()

func _on_upgrade_failed(reason: String) -> void:
	match reason:
		"not_enough_gold":
			build_hint_label.text = "Not enough gold for upgrade"
		"wave_running":
			build_hint_label.text = "Upgrades disabled during wave"
		"max_level":
			build_hint_label.text = "Defense already at max level"
		"no_selection":
			build_hint_label.text = "No defense selected"
		_:
			build_hint_label.text = "Upgrade unavailable"

func _connect_build_pads() -> void:
	if _map_instance == null:
		return
	var pads_root: Node = _map_instance.get_node_or_null("BuildPads")
	if pads_root == null:
		return
	for child: Node in pads_root.get_children():
		var pad: Area2D = child as Area2D
		if pad == null or not pad.has_signal("pad_clicked"):
			continue
		if not pad.is_connected("pad_clicked", _on_pad_clicked):
			pad.connect("pad_clicked", _on_pad_clicked)
	_set_build_pads_enabled(not _is_wave_running)

func _update_status_labels() -> void:
	var run_state: Node = get_node("/root/RunState")
	var current_round: int = int(run_state.get("current_round"))
	var total_rounds: int = int(run_state.get("total_rounds"))
	if total_rounds <= 0:
		total_rounds = 6
	round_label.text = "%d / %d" % [current_round, total_rounds]
	core_hp_label.text = str(int(run_state.get("core_hp")))
	gold_label.text = str(int(run_state.get("gold")))
	active_enemies_label.text = str(wave_controller.get_active_enemy_count())
	spawned_enemies_label.text = str(_spawned_count)
	leaked_enemies_label.text = str(_leaked_count)
	build_selection_label.text = _build_defense_id
	_refresh_selected_defense_panel()
	upgrade_button.disabled = _is_wave_running or not defense_controller.can_upgrade_selected_defense()
	sell_button.disabled = _is_wave_running or not defense_controller.can_sell_selected_defense()
	select_manguerazo_button.disabled = _is_wave_running
	select_cable_pelao_button.disabled = _is_wave_running

func _clear_enemy_layer() -> void:
	if enemy_layer == null:
		return
	for child: Node in enemy_layer.get_children():
		child.queue_free()

func _clear_defense_layer() -> void:
	if defense_layer == null:
		return
	for child: Node in defense_layer.get_children():
		child.queue_free()

func _set_build_pads_enabled(enabled: bool) -> void:
	if _map_instance == null:
		return
	var pads_root: Node = _map_instance.get_node_or_null("BuildPads")
	if pads_root == null:
		return
	for child: Node in pads_root.get_children():
		var pad: Area2D = child as Area2D
		if pad == null:
			continue
		pad.input_pickable = enabled

func get_phase_name() -> String:
	return _phase_name

func _apply_board_layout() -> void:
	_apply_gameplay_layout()

func _on_viewport_size_changed() -> void:
	_apply_gameplay_layout()
	_center_camera()

func _apply_gameplay_layout() -> void:
	if map_container == null:
		return

	var viewport_size: Vector2 = _get_layout_viewport_size()
	var top_bar_rect: Rect2 = Rect2(
		Vector2(OUTER_MARGIN, TOP_BAR_Y),
		Vector2(maxf(1.0, viewport_size.x - OUTER_MARGIN * 2.0), TOP_BAR_HEIGHT)
	)
	_set_control_rect(top_bar, top_bar_rect)
	_set_control_rect(top_bar_content, Rect2(
		Vector2(PANEL_INSET, 10.0),
		Vector2(maxf(1.0, top_bar_rect.size.x - PANEL_INSET * 2.0), 24.0)
	))

	var side_panel_height: float = maxf(420.0, viewport_size.y - SIDE_PANEL_Y - SIDE_PANEL_BOTTOM_MARGIN)
	var left_rect: Rect2 = Rect2(Vector2(OUTER_MARGIN, SIDE_PANEL_Y), Vector2(LEFT_PANEL_WIDTH, side_panel_height))
	var right_rect: Rect2 = Rect2(
		Vector2(maxf(left_rect.end.x + PANEL_GAP * 2.0, viewport_size.x - OUTER_MARGIN - RIGHT_PANEL_WIDTH), SIDE_PANEL_Y),
		Vector2(RIGHT_PANEL_WIDTH, side_panel_height)
	)
	_set_control_rect(left_panel, left_rect)
	_set_control_rect(left_panel_content, Rect2(
		Vector2(PANEL_INSET, PANEL_INSET),
		Vector2(maxf(1.0, left_rect.size.x - PANEL_INSET * 2.0), maxf(1.0, left_rect.size.y - PANEL_INSET * 2.0))
	))
	_set_control_rect(right_panel, right_rect)
	_set_control_rect(right_panel_content, Rect2(
		Vector2(PANEL_INSET, PANEL_INSET),
		Vector2(maxf(1.0, right_rect.size.x - PANEL_INSET * 2.0), maxf(1.0, right_rect.size.y - PANEL_INSET * 2.0))
	))

	var board_left: float = left_rect.end.x + PANEL_GAP
	var board_right: float = right_rect.position.x - PANEL_GAP
	var board_area: Rect2 = Rect2(
		Vector2(board_left, BOARD_TOP),
		Vector2(maxf(1.0, board_right - board_left), maxf(1.0, viewport_size.y - BOARD_TOP - BOARD_BOTTOM_MARGIN))
	)
	var map_scale: float = minf(board_area.size.x / MAP_DESIGN_SIZE.x, board_area.size.y / MAP_DESIGN_SIZE.y)
	map_scale = clampf(map_scale, 0.65, 1.0)
	var map_size: Vector2 = MAP_DESIGN_SIZE * map_scale
	var map_position: Vector2 = Vector2(
		board_area.position.x + maxf(0.0, (board_area.size.x - map_size.x) * 0.5),
		board_area.position.y + BOARD_TOP_PADDING
	)
	if map_position.y + map_size.y > board_area.end.y:
		map_position.y = board_area.end.y - map_size.y
	map_container.position = map_position
	map_container.scale = Vector2(map_scale, map_scale)

func _set_control_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.position = rect.position
	control.size = rect.size

func _get_layout_viewport_size() -> Vector2:
	if _layout_viewport_override.x > 0.0 and _layout_viewport_override.y > 0.0:
		return _layout_viewport_override
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return DESIGN_VIEWPORT_SIZE
	return viewport_size

func apply_gameplay_layout_for_debug(viewport_size: Vector2) -> void:
	_layout_viewport_override = viewport_size
	_apply_gameplay_layout()
	_center_camera()

func get_layout_debug_rects() -> Dictionary:
	var map_rect: Rect2 = Rect2(map_container.position, MAP_DESIGN_SIZE * map_container.scale)
	return {
		"viewport": Rect2(Vector2.ZERO, _get_layout_viewport_size()),
		"top_bar": _control_global_rect(top_bar),
		"left_panel": _control_global_rect(left_panel),
		"right_panel": _control_global_rect(right_panel),
		"map_playfield": map_rect,
		"phase_action_button": _control_global_rect(action_button),
		"force_complete_button": _control_global_rect(force_complete_button),
		"select_manguerazo_button": _control_global_rect(select_manguerazo_button),
		"select_cable_pelao_button": _control_global_rect(select_cable_pelao_button),
		"upgrade_button": _control_global_rect(upgrade_button),
		"sell_button": _control_global_rect(sell_button)
	}

func _control_global_rect(control: Control) -> Rect2:
	if control == null:
		return Rect2()
	return control.get_global_rect()

func request_sell_selected_defense() -> void:
	if _is_wave_running:
		build_hint_label.text = "Selling disabled during wave"
		return
	var refund: int = defense_controller.sell_selected_defense()
	if refund <= 0:
		build_hint_label.text = "No sellable defense selected"
		return
	_update_status_labels()

func request_upgrade_selected_defense() -> void:
	if _is_wave_running:
		build_hint_label.text = "Upgrades disabled during wave"
		return
	if not defense_controller.upgrade_selected_defense():
		return
	_update_status_labels()

func get_selected_defense_id() -> String:
	var defense: DefenseActor = defense_controller.get_selected_defense()
	if defense == null:
		return ""
	return defense.defense_id

func get_selected_refund_amount() -> int:
	return defense_controller.get_selected_refund_amount()

func get_selected_level() -> int:
	var defense: DefenseActor = defense_controller.get_selected_defense()
	if defense == null:
		return 0
	return defense.level

func get_selected_upgrade_cost() -> int:
	return defense_controller.get_selected_upgrade_cost()

func get_selected_damage() -> float:
	var defense: DefenseActor = defense_controller.get_selected_defense()
	if defense == null:
		return 0.0
	return defense.damage

func get_selected_range() -> float:
	var defense: DefenseActor = defense_controller.get_selected_defense()
	if defense == null:
		return 0.0
	return defense.get_effective_range()

func upgrade_selected_for_debug() -> bool:
	return defense_controller.upgrade_selected_defense()

func sell_selected_for_debug() -> int:
	return defense_controller.sell_selected_defense()

func select_first_defense_for_debug() -> bool:
	for child: Node in defense_layer.get_children():
		var defense: DefenseActor = child as DefenseActor
		if defense == null:
			continue
		return defense_controller.select_defense(defense)
	return false

func select_defense_by_id_for_debug(defense_id: String) -> bool:
	if defense_id.is_empty():
		return false
	for child: Node in defense_layer.get_children():
		var defense: DefenseActor = child as DefenseActor
		if defense == null:
			continue
		if defense.defense_id != defense_id:
			continue
		return defense_controller.select_defense(defense)
	return false

func select_defense_by_id_at_index_for_debug(defense_id: String, match_index: int) -> bool:
	if defense_id.is_empty() or match_index < 0:
		return false
	var current_match: int = 0
	for child: Node in defense_layer.get_children():
		var defense: DefenseActor = child as DefenseActor
		if defense == null:
			continue
		if defense.defense_id != defense_id:
			continue
		if current_match == match_index:
			return defense_controller.select_defense(defense)
		current_match += 1
	return false

func select_build_manguerazo() -> void:
	_build_defense_id = "manguerazo"
	build_hint_label.text = "Build selected: manguerazo"
	_update_status_labels()

func select_build_cable_pelao() -> void:
	_build_defense_id = "cable_pelao"
	build_hint_label.text = "Build selected: cable_pelao"
	_update_status_labels()

func build_debug_first_pad_with(defense_id: String) -> bool:
	if defense_id.is_empty():
		return false
	_build_defense_id = defense_id
	return build_debug_first_pad()

func _refresh_selected_defense_panel() -> void:
	var defense: DefenseActor = defense_controller.get_selected_defense()
	if defense == null:
		selected_defense_label.text = "None"
		selected_level_label.text = "-"
		selected_damage_label.text = "0"
		selected_range_label.text = "0"
		selected_fire_rate_label.text = "0"
		upgrade_cost_label.text = "0"
		sell_refund_label.text = "0"
		upgrade_button.disabled = true
		sell_button.disabled = true
		return
	selected_defense_label.text = defense.defense_id
	selected_level_label.text = str(defense.level)
	selected_damage_label.text = "%.1f" % defense.damage
	selected_range_label.text = "%.1f" % defense.get_effective_range()
	selected_fire_rate_label.text = "%.2f/s" % defense.fire_rate
	upgrade_cost_label.text = str(defense.get_upgrade_cost())
	sell_refund_label.text = str(defense_controller.get_selected_refund_amount())

func get_run_range_multiplier() -> float:
	return float(get_node("/root/RunState").get("defense_range_multiplier"))

func get_run_crit_chance() -> float:
	return float(get_node("/root/RunState").get("global_crit_chance"))

func get_total_rounds() -> int:
	return int(get_node("/root/RunState").get("total_rounds"))
