extends Resource

class_name EnemyDef

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var display_name_es: String = ""
@export_multiline var description_es: String = ""
@export var flavor_text_es: String = ""
@export_file("*.tscn") var scene_path: String = ""
@export var tags: PackedStringArray = []

@export var base_hp: float = 1.0
@export var base_speed: float = 1.0
@export var base_armor: int = 0
@export var leak_damage: int = 1
@export var gold_reward: int = 1

@export var abilities: PackedStringArray = []
@export var weakness_tags: PackedStringArray = []
@export var resistance_tags: PackedStringArray = []
@export var is_boss: bool = false
@export var visual_color_key: String = ""
