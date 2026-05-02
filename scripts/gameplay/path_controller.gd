extends Node

class_name PathController

var paths: Dictionary = {}

func register_path(path_id: String, path_node: Path2D) -> void:
    paths[path_id] = path_node

func get_path_node(path_id: String) -> Path2D:
    return paths.get(path_id)

func clear_paths() -> void:
    paths.clear()
