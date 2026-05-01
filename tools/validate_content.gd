extends SceneTree

func _init() -> void:
	print("Running content validation...")

	var content_db_script: Script = load("res://autoload/content_db.gd")
	var content_db: Node = content_db_script.new()

	get_root().add_child(content_db)

	content_db.load_all()
	var errors: Array[String] = content_db.validate_all()

	if errors.is_empty():
		print("Content validation OK.")
		quit(0)
		return

	print("Content validation failed:")
	for error in errors:
		print("- ", error)

	quit(1)
