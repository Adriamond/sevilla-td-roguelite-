extends Resource

class_name ItemDef

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
@export var flavor_text: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var tags: PackedStringArray = []

@export var effect_hooks: PackedStringArray = []
@export var effect_values: Dictionary = {}
@export var drawback_description: String = ""
@export var balance_risk: String = ""
