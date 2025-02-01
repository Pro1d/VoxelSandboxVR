@tool
extends EditorScript

func _run() -> void:
	var m := MetaSave.create()
	ResourceSaver.save(m, "res://test.tres")
