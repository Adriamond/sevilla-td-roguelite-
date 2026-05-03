extends Node

var enemies: Dictionary = {}
var defenses: Dictionary = {}
var items: Dictionary = {}
var characters: Dictionary = {}
var maps: Dictionary = {}
var rounds: Dictionary = {}
var room_interactions: Dictionary = {}
var status_effects: Dictionary = {}

const ID_PATTERN: String = "^[a-z0-9]+(_[a-z0-9]+)*$"

const DATA_SOURCES: Dictionary = {
    "enemies": {"dir": "res://data/enemies", "script": "res://scripts/defs/enemy_def.gd"},
    "defenses": {"dir": "res://data/defenses", "script": "res://scripts/defs/defense_def.gd"},
    "items": {"dir": "res://data/items", "script": "res://scripts/defs/item_def.gd"},
    "characters": {"dir": "res://data/characters", "script": "res://scripts/defs/character_def.gd"},
    "maps": {"dir": "res://data/maps", "script": "res://scripts/defs/map_def.gd"},
    "rounds": {"dir": "res://data/rounds", "script": "res://scripts/defs/round_def.gd"},
    "room_interactions": {"dir": "res://data/room_interactions", "script": "res://scripts/defs/room_interaction_def.gd"},
    "status_effects": {"dir": "res://data/status_effects", "script": "res://scripts/defs/status_effect_def.gd"}
}

func load_all() -> void:
    enemies.clear()
    defenses.clear()
    items.clear()
    characters.clear()
    maps.clear()
    rounds.clear()
    room_interactions.clear()
    status_effects.clear()

    _load_category("enemies", enemies)
    _load_category("defenses", defenses)
    _load_category("items", items)
    _load_category("characters", characters)
    _load_category("maps", maps)
    _load_category("rounds", rounds)
    _load_category("room_interactions", room_interactions)
    _load_category("status_effects", status_effects)

func validate_all() -> Array[String]:
    var errors: Array[String] = []
    errors.append_array(_validate_category(enemies, "enemies", true, false))
    errors.append_array(_validate_category(defenses, "defenses", true, false))
    errors.append_array(_validate_category(items, "items", false, false))
    errors.append_array(_validate_category(characters, "characters", false, false))
    errors.append_array(_validate_category(maps, "maps", true, false))
    errors.append_array(_validate_category(rounds, "rounds", false, true))
    errors.append_array(_validate_category(room_interactions, "room_interactions", false, false))
    errors.append_array(_validate_category(status_effects, "status_effects", false, false))

    for enemy_id: String in enemies.keys():
        var enemy: Resource = enemies[enemy_id]
        _validate_positive_number(errors, enemy, "enemies", enemy_id, "base_hp", false)
        _validate_positive_number(errors, enemy, "enemies", enemy_id, "base_speed", false)
        _validate_positive_number(errors, enemy, "enemies", enemy_id, "gold_reward", true)

    for defense_id: String in defenses.keys():
        var defense: Resource = defenses[defense_id]
        _validate_positive_number(errors, defense, "defenses", defense_id, "base_cost", true)
        _validate_positive_number(errors, defense, "defenses", defense_id, "base_damage", true)

    for effect_id: String in status_effects.keys():
        var status_effect: Resource = status_effects[effect_id]
        _validate_positive_number(errors, status_effect, "status_effects", effect_id, "duration", false)

    for interaction_id: String in room_interactions.keys():
        var interaction: Resource = room_interactions[interaction_id]
        _validate_positive_number(errors, interaction, "room_interactions", interaction_id, "cost_gold", true)
        _validate_positive_number(errors, interaction, "room_interactions", interaction_id, "cost_room_charges", true)
        _validate_positive_number(errors, interaction, "room_interactions", interaction_id, "max_uses_per_run", true)
        _validate_positive_number(errors, interaction, "room_interactions", interaction_id, "max_uses_per_round", true)

    for round_id: String in rounds.keys():
        var round_def: Resource = rounds[round_id]
        if not _has_property(round_def, "wave_steps"):
            continue

        var wave_steps: Array = round_def.get("wave_steps")
        for i: int in range(wave_steps.size()):
            var wave_step_variant: Variant = wave_steps[i]
            if wave_step_variant == null or not (wave_step_variant is Resource):
                errors.append("rounds/%s wave_steps[%d] is not a valid WaveStepDef resource." % [round_id, i])
                continue
            var wave_step: Resource = wave_step_variant
            if not _has_property(wave_step, "enemy_id"):
                errors.append("rounds/%s wave_steps[%d] is missing enemy_id." % [round_id, i])
                continue
            var enemy_ref_id: String = String(wave_step.get("enemy_id")).strip_edges()
            if enemy_ref_id.is_empty():
                errors.append("rounds/%s wave_steps[%d] has empty enemy_id." % [round_id, i])
            elif not enemies.has(enemy_ref_id):
                errors.append("rounds/%s wave_steps[%d] references missing enemy_id '%s'." % [round_id, i, enemy_ref_id])

        var has_boss: bool = bool(round_def.get("has_boss")) if _has_property(round_def, "has_boss") else false
        var boss_enemy_id: String = String(round_def.get("boss_enemy_id")).strip_edges() if _has_property(round_def, "boss_enemy_id") else ""
        if has_boss:
            if boss_enemy_id.is_empty():
                errors.append("rounds/%s has_boss=true but boss_enemy_id is empty." % round_id)
            elif not enemies.has(boss_enemy_id):
                errors.append("rounds/%s boss_enemy_id '%s' does not exist in enemies." % [round_id, boss_enemy_id])
            else:
                var boss_enemy: Resource = enemies[boss_enemy_id]
                var is_boss: bool = bool(boss_enemy.get("is_boss")) if _has_property(boss_enemy, "is_boss") else false
                if not is_boss:
                    errors.append("rounds/%s boss_enemy_id '%s' must reference an enemy with is_boss=true." % [round_id, boss_enemy_id])

    return errors

func get_enemy(id: String) -> Resource:
    return enemies.get(id)

func get_defense(id: String) -> Resource:
    return defenses.get(id)

func get_item(id: String) -> Resource:
    return items.get(id)

func get_character(id: String) -> Resource:
    return characters.get(id)

func get_map(id: String) -> Resource:
    return maps.get(id)

func get_round(id: String) -> Resource:
    return rounds.get(id)

func _load_category(category_name: String, target: Dictionary) -> void:
    var source: Dictionary = DATA_SOURCES.get(category_name, {})
    var base_dir: String = String(source.get("dir", ""))
    var expected_script: String = String(source.get("script", ""))
    if base_dir.is_empty():
        return

    var files: Array[String] = _collect_tres_files(base_dir)
    for file_path: String in files:
        var resource: Resource = load(file_path)
        if resource == null:
            continue
        if not expected_script.is_empty() and resource.get_script() != load(expected_script):
            continue

        var id: String = String(resource.get("id")).strip_edges() if _has_property(resource, "id") else ""
        if not id.is_empty():
            if not target.has(id):
                target[id] = resource
            else:
                var existing: Variant = target[id]
                if existing is Array:
                    var bucket: Array = existing
                    bucket.append(resource)
                    target[id] = bucket
                else:
                    target[id] = [existing, resource]
        else:
            target[file_path] = resource

func _collect_tres_files(base_dir: String) -> Array[String]:
    var results: Array[String] = []
    var dir: DirAccess = DirAccess.open(base_dir)
    if dir == null:
        return results

    dir.list_dir_begin()
    while true:
        var entry: String = dir.get_next()
        if entry.is_empty():
            break
        if entry.begins_with("."):
            continue
        var full_path: String = "%s/%s" % [base_dir, entry]
        if dir.current_is_dir():
            results.append_array(_collect_tres_files(full_path))
        elif entry.to_lower().ends_with(".tres"):
            results.append(full_path)
    dir.list_dir_end()
    return results

func _validate_category(
    category: Dictionary,
    category_name: String,
    require_scene_path: bool,
    allow_missing_description: bool
) -> Array[String]:
    var errors: Array[String] = []
    var id_regex: RegEx = RegEx.new()
    id_regex.compile(ID_PATTERN)

    for key: Variant in category.keys():
        var resource_or_list: Variant = category[key]
        if resource_or_list is Array:
            errors.append("%s has duplicate id '%s'." % [category_name, String(key)])
            var list: Array = resource_or_list
            for dup_idx: int in range(list.size()):
                _validate_single_resource(
                    errors,
                    list[dup_idx],
                    category_name,
                    String(key),
                    require_scene_path,
                    allow_missing_description,
                    id_regex
                )
            continue
        _validate_single_resource(
            errors,
            resource_or_list,
            category_name,
            String(key),
            require_scene_path,
            allow_missing_description,
            id_regex
        )
    return errors

func _validate_single_resource(
    errors: Array[String],
    resource: Resource,
    category_name: String,
    key: String,
    require_scene_path: bool,
    allow_missing_description: bool,
    id_regex: RegEx
) -> void:
    if resource == null:
        errors.append("%s/%s is null." % [category_name, key])
        return

    if not _has_property(resource, "id"):
        errors.append("%s/%s is missing property 'id'." % [category_name, key])
        return

    var id: String = String(resource.get("id")).strip_edges()
    if id.is_empty():
        errors.append("%s/%s has missing id." % [category_name, key])
    elif id_regex.search(id) == null:
        errors.append("%s/%s has invalid id '%s'. Use lowercase snake_case." % [category_name, key, id])

    _validate_required_string(errors, resource, category_name, id, "display_name")
    _validate_required_string(errors, resource, category_name, id, "display_name_es")
    if not allow_missing_description:
        _validate_required_string(errors, resource, category_name, id, "description")
        _validate_required_string(errors, resource, category_name, id, "description_es")

    if require_scene_path:
        if not _has_property(resource, "scene_path"):
            errors.append("%s/%s is missing property 'scene_path'." % [category_name, id])
        else:
            var scene_path: String = String(resource.get("scene_path")).strip_edges()
            if scene_path.is_empty():
                errors.append("%s/%s has empty scene_path." % [category_name, id])
            elif not ResourceLoader.exists(scene_path, "PackedScene"):
                errors.append("%s/%s has scene_path '%s' that does not exist or is not a .tscn scene." % [category_name, id, scene_path])

func _validate_required_string(
    errors: Array[String],
    resource: Resource,
    category_name: String,
    id: String,
    property_name: String
) -> void:
    if not _has_property(resource, property_name):
        return
    var value: String = String(resource.get(property_name)).strip_edges()
    if value.is_empty():
        errors.append("%s/%s has missing %s." % [category_name, id, property_name])

func _validate_positive_number(
    errors: Array[String],
    resource: Resource,
    category_name: String,
    id: String,
    property_name: String,
    allow_zero: bool
) -> void:
    if not _has_property(resource, property_name):
        return
    var value: float = float(resource.get(property_name))
    if allow_zero:
        if value < 0.0:
            errors.append("%s/%s has invalid %s=%s (must be >= 0)." % [category_name, id, property_name, str(value)])
    elif value <= 0.0:
        errors.append("%s/%s has invalid %s=%s (must be > 0)." % [category_name, id, property_name, str(value)])

func _has_property(resource: Resource, property_name: String) -> bool:
    for prop: Dictionary in resource.get_property_list():
        if String(prop.get("name", "")) == property_name:
            return true
    return false
