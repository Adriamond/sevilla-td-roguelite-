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
var picked_item_ids: Array[String] = []
var built_defense_ids: Array[String] = []

func reset_run(new_seed: int, new_character_id: String, new_map_id: String) -> void:
	run_seed = new_seed
	character_id = new_character_id
	map_id = new_map_id
	current_round = 1
	gold = 140
	core_hp = 20
	room_charges = 2
	picked_item_ids.clear()
	built_defense_ids.clear()
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

func is_defeated() -> bool:
	return core_hp <= 0
