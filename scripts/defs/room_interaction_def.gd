extends Resource

class_name RoomInteractionDef

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var display_name_es: String = ""
@export_multiline var description_es: String = ""
@export var success_text_es: String = ""
@export var failure_text_es: String = ""
@export var flavor_text_es: String = ""

@export var cost_gold: int = 0
@export var cost_room_charges: int = 0
@export var max_uses_per_run: int = 1
@export var max_uses_per_round: int = 1

@export var benefit_tags: PackedStringArray = []
@export var risk_tags: PackedStringArray = []
@export var effect_values: Dictionary = {}
