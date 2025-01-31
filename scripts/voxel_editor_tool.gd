class_name VoxelEditorTool
extends Node3D

signal tool_pressed(pos: Vector3)
signal tool_moved(pos: Vector3)
signal tool_released(pos: Vector3)
#signal tool_cancelled()
#signal tool_mode_changed(mode: Mode)

enum Mode {
	DRAW,
	ERASE,
	BOX_DRAW,
	BOX_ERASE,
	PAINT,
	FILL,
}

@export var enabled := true:
	set(e):
		if enabled != e:
			enabled = e
			visible = enabled
			pressed = false

var pressed := false
var _last_emitted_position := Vector3(NAN, NAN, NAN)

@onready var controller := get_parent() as XRController3D
@onready var _pointer := %Pointer as Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(controller != null)
	
	controller.button_pressed.connect(_on_controller_button_pressed)
	controller.button_released.connect(_on_controller_button_released)
	
	#_tool_selection_wheel.action_triggered.connect(_on_tool_selection_wheel_action_triggered)

func _process(_delta: float) -> void:
	if not enabled:
		return
	# Tool moved
	if not _last_emitted_position.is_finite() or _last_emitted_position.distance_squared_to(_pointer.global_position) > 0.005 * 0.005:
		_last_emitted_position = _pointer.global_position
		tool_moved.emit(_pointer.global_position)

func _on_controller_button_pressed(input_name: String) ->  void:
	if not enabled:
		return
	if input_name == "trigger_click":
		_last_emitted_position = _pointer.global_position
		pressed = true
		tool_pressed.emit(_pointer.global_position)

func _on_controller_button_released(input_name: String) ->  void:
	if not enabled:
		return
	if input_name == "trigger_click":
		if pressed:
			_last_emitted_position = _pointer.global_position
			pressed = false
			tool_released.emit(_pointer.global_position)

func pointer_position() -> Vector3:
	return _pointer.global_position

#func _on_tool_selection_wheel_action_triggered(action: Mode) -> void:
	#if pressed:
		#pressed = false
		#tool_cancelled.emit()
