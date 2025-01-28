class_name VoxelTransformerTool
extends Node3D

signal transformed(t: Transform3D)
signal transformed_decompose(t: Vector3, r: Basis, s: float, o: Vector3)

@export var other_transformer_tool : VoxelTransformerTool
@export var is_master := false

var _previous_transform : Transform3D
var _pressed := false

@onready var controller := get_parent() as XRController3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(other_transformer_tool != null)
	
	controller.button_pressed.connect(_on_controller_button_pressed)
	controller.button_released.connect(_on_controller_button_released)
	is_master = not other_transformer_tool.is_master

func _process(_delta: float) -> void:
	if _pressed:
		if other_transformer_tool._pressed:
			if not other_transformer_tool.is_master:
				var this_curr := global_transform.origin
				var this_prev := _previous_transform.origin
				var other_curr := other_transformer_tool.global_transform.origin
				var other_prev := other_transformer_tool._previous_transform.origin
				var curr_this_other := other_curr - this_curr
				var prev_this_other := other_prev - this_prev
				var curr_center := (other_curr + this_curr) / 2
				var prev_center := (other_prev + this_prev) / 2
				if not curr_this_other.is_zero_approx() and not prev_this_other.is_zero_approx():
					var curr_len := curr_this_other.length()
					var prev_len := prev_this_other.length()
					var curr_tan := curr_this_other / curr_len
					var prev_tan := prev_this_other / prev_len
					#var up := (
						#Vector3.LEFT
						#if curr_tan.abs().is_equal_approx(Vector3.UP) or prev_tan.abs().is_equal_approx(Vector3.UP)
						#else Vector3.UP
					#)
					#var t_prev := Transform3D(Basis(), prev_center).looking_at(curr_tan, up)
					#t_prev.basis.scaled(prev_len * Vector3.ONE)
					#var t_curr := Transform3D(Basis(), curr_center).looking_at(prev_tan, up)
					#t_curr.basis.scaled(curr_len * Vector3.ONE)
					#var T := t_curr * t_prev.inverse()
					var t := curr_center - prev_center
					var s := curr_len / prev_len
					var r := Basis.from_euler(Vector3(0, Vector2(prev_tan.x, -prev_tan.z).angle_to(Vector2(curr_tan.x, -curr_tan.z)), 0))
					var o := curr_center
					#transformed.emit(Transform3D(T.basis, T.origin))
					transformed_decompose.emit(t, r, s, o)
		else:
			var curr := global_transform
			var prev := _previous_transform
			if not prev.is_equal_approx(curr):
				var t := curr.origin - prev.origin
				# T * prev = curr  <=>  T = curr * prev^-1
				var T := curr * prev.inverse()
				transformed.emit(T)
				transformed_decompose.emit(t, T.basis, 1.0, curr.origin)
		
		_previous_transform = global_transform

func _on_controller_button_pressed(action: String) -> void:
	if action == "grip_click":
		_pressed = true
		_previous_transform = global_transform

func _on_controller_button_released(action: String) -> void:
	if action == "grip_click":
		_pressed = false
