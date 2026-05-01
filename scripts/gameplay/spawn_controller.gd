extends Node

class_name SpawnController

@export var enemy_parent_path: NodePath

func spawn_enemy(enemy_id: String, path_id: String = "main", is_elite: bool = false) -> Node:
    # TODO: Load EnemyDef from ContentDB and instantiate scene.
    # TODO: Assign path and elite modifiers.
    _ = path_id
    _ = is_elite
    print("Spawn enemy placeholder: ", enemy_id)
    return null
