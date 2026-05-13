extends Node

signal gold_changed(value: int)
signal core_hp_changed(value: int)
signal round_changed(value: int)

var run_seed: int = 0
var character_id: String = ""
var map_id: String = ""
var current_round: int = 0
var gold: int = 0
var core_hp: int = 0
var room_charges: int = 0
var total_rounds: int = 0
var picked_item_ids: Array[String] = []
var built_defense_ids: Array[String] = []
var used_room_interaction_ids: Array[String] = []
var defense_range_multiplier: float = 1.0
var global_crit_chance: float = 0.0
var pending_next_wave_crit_bonus: float = 0.0
var current_wave_crit_bonus: float = 0.0

func reset_run(new_seed: int, new_character_id: String, new_map_id: String) -> void:
	run_seed = new_seed
	character_id = new_character_id
	map_id = new_map_id
	current_round = 1
	gold = 140
	core_hp = 20
	room_charges = 2
	total_rounds = 0
	defense_range_multiplier = 1.0
	global_crit_chance = 0.0
	pending_next_wave_crit_bonus = 0.0
	current_wave_crit_bonus = 0.0
	picked_item_ids.clear()
	built_defense_ids.clear()
	used_room_interaction_ids.clear()
	gold_changed.emit(gold)
	core_hp_changed.emit(core_hp)
	round_changed.emit(current_round)

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func damage_core(amount: int) -> void:
	core_hp = max(0, core_hp - amount)
	core_hp_changed.emit(core_hp)

func heal_core(amount: int) -> void:
	if amount <= 0:
		return
	core_hp += amount
	core_hp_changed.emit(core_hp)

func mark_room_interaction_used(interaction_id: String) -> void:
	if interaction_id.is_empty():
		return
	if used_room_interaction_ids.has(interaction_id):
		return
	used_room_interaction_ids.append(interaction_id)

func has_used_room_interaction(interaction_id: String) -> bool:
	return used_room_interaction_ids.has(interaction_id)

func grant_next_wave_crit_bonus(amount: float) -> void:
	if amount <= 0.0:
		return
	pending_next_wave_crit_bonus += amount

func activate_next_wave_room_bonuses() -> void:
	current_wave_crit_bonus = pending_next_wave_crit_bonus
	pending_next_wave_crit_bonus = 0.0

func clear_current_wave_room_bonuses() -> void:
	current_wave_crit_bonus = 0.0

func get_total_crit_chance() -> float:
	return min(0.5, global_crit_chance + current_wave_crit_bonus)

func is_defeated() -> bool:
	return core_hp <= 0
