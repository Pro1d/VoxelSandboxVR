class_name WheelBase
extends Node3D

@export var enabled := true:
	set(e):
		if enabled != e:
			enabled = e
			visible = e
@export var quadrant_count := 6

var _input_action_tool_selector := "primary"
var _last_pointed_quadrant := -1

@onready var controller := get_parent() as XRController3D
@onready var ring_mesh := %RingMeshInstance3D as MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(controller != null)
	var webxr_interface := XRServer.find_interface("WebXR")
	if webxr_interface:
		XRToolsUserSettings.webxr_primary_changed.connect(self._on_webxr_primary_changed)
		_on_webxr_primary_changed(XRToolsUserSettings.get_real_webxr_primary())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var joystick_position := controller.get_vector2(_input_action_tool_selector)
	var joystick_angle := joystick_position.angle()
	const deadzone := 0.1
	var joystick_length := lerpf(deadzone, 1.0, minf(joystick_position.length(), 1.0))
	
	_update_inclination(joystick_angle, joystick_length)
	if enabled:
		handle_joystick_input(joystick_angle, joystick_length)

func _update_inclination(angle: float, strength: float) -> void:
	var inclination := -(strength ** 2) * PI * 0.07
	ring_mesh.transform.basis = Basis(Vector3(0, 0, 1).rotated(Vector3.UP, angle), inclination)

func _on_webxr_primary_changed(webxr_primary: int) -> void:
	# Default to thumbstick.
	if webxr_primary == 0:
		webxr_primary = XRToolsUserSettings.WebXRPrimary.THUMBSTICK

	# Re-assign the action name on all the applicable functions.
	_input_action_tool_selector = XRToolsSettings.get_webxr_primary_action(webxr_primary)

func handle_joystick_input(joystick_angle: float, joystick_length: float) -> void:
	if joystick_length > 0.4:
		var pointed_quadrant := get_index_from_angle(joystick_angle)
		if pointed_quadrant != _last_pointed_quadrant:
			on_pointing_changed(pointed_quadrant, _last_pointed_quadrant)
			_last_pointed_quadrant = pointed_quadrant
	elif _last_pointed_quadrant >= 0:
		on_pointing_exited(_last_pointed_quadrant)
		_last_pointed_quadrant = -1

func on_pointing_changed(_pointed_quadrant: int, __last_pointed_quadrant: int) -> void:
	pass

func on_pointing_exited(__last_pointed_quadrant: int) -> void:
	pass

func get_index_from_angle(angle: float) -> int:
	return floori(fposmod(angle + TAU * .5 / quadrant_count, TAU) / TAU * quadrant_count)

func get_angle_from_index(quadrant: int) -> float:
	return TAU * quadrant / quadrant_count
