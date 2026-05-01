extends Node

class_name TelemetrySystem

var current_metrics: RunMetrics = RunMetrics.new()

func start_run_metrics(seed: int, character_id: String, map_id: String) -> void:
    current_metrics = RunMetrics.new()
    current_metrics.seed = seed
    current_metrics.character_id = character_id
    current_metrics.map_id = map_id

func export_metrics() -> void:
    # TODO: Write local JSON or CSV under user://telemetry/.
    pass
