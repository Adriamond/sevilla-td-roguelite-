extends Resource

class_name DefenseDef

enum DefenseCategory {
    AIR,
    GROUND,
    WALL
}

enum DefenseElement {
    HUMO,
    AGUA,
    TURBO,
    ORO,
    PACTO,
    METAL
}

enum Rarity {
    COMMON,
    RARE,
    EPIC
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var display_name_es: String = ""
@export_multiline var description_es: String = ""
@export var flavor_text_es: String = ""
@export_file("*.tscn") var scene_path: String = ""

@export var category: DefenseCategory = DefenseCategory.GROUND
@export var element: DefenseElement = DefenseElement.METAL
@export var rarity: Rarity = Rarity.COMMON

@export var base_cost: int = 50
@export var base_damage: float = 1.0
@export var base_fire_rate: float = 1.0
@export var base_range: float = 64.0
@export var targeting_mode: String = "first"

@export var effect_ids: PackedStringArray = []
@export var upgrade_1_description: String = ""
@export var upgrade_2_description: String = ""
@export var upgrade_1_description_es: String = ""
@export var upgrade_2_description_es: String = ""
@export var strong_against_tags: PackedStringArray = []
@export var weak_against_tags: PackedStringArray = []
@export var synergy_tags: PackedStringArray = []
@export var balance_risk: String = ""
