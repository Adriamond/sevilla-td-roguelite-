extends Resource

class_name StatusEffectDef

enum StackingRule {
    REFRESH,
    STACK_INTENSITY,
    STACK_DURATION,
    IGNORE_IF_PRESENT
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var display_name_es: String = ""
@export_multiline var description_es: String = ""
@export var duration: float = 1.0
@export var stacking_rule: StackingRule = StackingRule.REFRESH
@export var effect_values: Dictionary = {}
@export var visual_key: String = ""
