extends Node

class_name EventBus

signal enemy_spawned(enemy: Node)
signal enemy_died(enemy: Node, enemy_id: String)
signal enemy_reached_end(enemy: Node, leak_damage: int)

signal wave_started(round_index: int)
signal wave_completed(round_index: int)

signal defense_built(defense_id: String)
signal defense_sold(defense_id: String)
signal defense_upgraded(defense_id: String, new_level: int)

signal reward_offered(item_ids: Array[String])
signal reward_selected(item_id: String)

signal room_interaction_used(interaction_id: String)
