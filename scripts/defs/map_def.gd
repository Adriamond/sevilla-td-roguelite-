extends Resource

class_name MapDef

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_file("*.tscn") var scene_path: String = ""
@export var ground_path_ids: PackedStringArray = []
@export var air_path_ids: PackedStringArray = []
@export var build_pad_groups: Dictionary = {}
@export var gimmick_id: String = ""
@export var music_id: String = ""
