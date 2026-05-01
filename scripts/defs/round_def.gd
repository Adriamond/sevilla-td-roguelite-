extends Resource

class_name RoundDef

@export var id: String = ""
@export var round_index: int = 1
@export var display_name: String = ""
@export var wave_steps: Array[Resource] = []
@export var base_gold_reward: int = 45
@export var has_elite: bool = false
@export var has_boss: bool = false
@export var boss_enemy_id: String = ""
@export var dominant_enemy_tags: PackedStringArray = []
@export var reward_table_id: String = ""
