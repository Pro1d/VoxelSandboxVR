class_name HoldToPressButton
extends TextureButton

const ShaderRes := preload("res://resources/materials/hold_to_press_button.material")

signal hold_pressed()

@export var hold_timeout := 2.0

var _shader : ShaderMaterial
var _timer : Timer
var is_hold_pressed := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	
	if _shader == null:
		_shader = ShaderRes.duplicate()
		material = _shader
	_clear_progress()
	
	_timer = Timer.new()
	_timer.wait_time = hold_timeout
	_timer.one_shot = true
	_timer.timeout.connect(_on_hold_timeout)
	add_child(_timer, false, InternalMode.INTERNAL_MODE_BACK)

func _process(_delta: float) -> void:
	if not _timer.is_stopped() or is_hold_pressed:
		var left_ratio := _timer.time_left / _timer.wait_time if not is_hold_pressed else 0.0
		var angle_ratio := 1.0 - left_ratio * left_ratio
		_shader.set_shader_parameter("progress_angle", TAU * angle_ratio)

func _clear_progress() -> void:
	_shader.set_shader_parameter("progress_angle", 0.0)

func _on_button_down() -> void:
	is_hold_pressed = false
	_timer.start()

func _on_button_up() -> void:
	is_hold_pressed = false
	_timer.stop()
	_clear_progress()

func _on_hold_timeout() -> void:
	is_hold_pressed = true
	hold_pressed.emit()
