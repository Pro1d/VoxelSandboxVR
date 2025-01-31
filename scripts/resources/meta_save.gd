class_name MetaSave
extends Resource


@export var creation_date : String
@export var modification_date : String

static func create() -> MetaSave:
	var m := MetaSave.new()
	m.creation_date = _get_current_time_date_string()
	m.modification_date = m.creation_date
	return m
	
func update_modification_time() -> void:
	modification_date = _get_current_time_date_string()

static func _get_current_time_date_string() -> String:
	return Time.get_datetime_string_from_system(false) # utc=false
