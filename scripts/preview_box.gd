class_name PreviewBox
extends MeshInstance3D

@export var margin := 0.0 :
	set(m):
		margin = m
		_update_margin()
@export var _displayed_corner_min := _corner_min
@export var _displayed_corner_max := _corner_max
@export var animation_duration := 0.15
@export var color := Color.RED :
	set(c):
		color = c
		_update_color()
@export var opacity := 1.0 :
	set(o):
		opacity = o
		_update_opacity()
var _corner_min := Vector3.ONE * -0.5
var _corner_max := Vector3.ONE * 0.5
var _tween_geometry : Tween
@onready var _box_mesh := mesh as BoxMesh
@onready var _mat := get_surface_override_material(0) as ShaderMaterial

func _ready() -> void:
	_update_margin()
	_update_color()
	_update_opacity()

func _update_margin() -> void:
	if _mat == null: return
	_mat.set_shader_parameter("margin", margin)

func _update_color() -> void:
	if _mat == null: return
	_mat.set_shader_parameter("albedo", color)
	
func _update_opacity() -> void:
	if _mat == null: return
	_mat.set_shader_parameter("alpha", opacity)

func set_geometry(corner1: Vector3i, corner2: Vector3i, animate: bool) -> void:
	var c_min := Vector3(corner1.min(corner2)) - Vector3.ONE * .5
	var c_max := Vector3(corner1.max(corner2)) + Vector3.ONE * .5
	if (
		_corner_min.is_equal_approx(c_min)
		and _corner_max.is_equal_approx(c_max)
		and animate
		and (_tween_geometry != null and _tween_geometry.is_running())
	):
		return # current animation is already targetting given geometry
	
	if _tween_geometry != null:
		_tween_geometry.kill()
		_tween_geometry = null
	
	if animate:
		_tween_geometry = create_tween()
		_tween_geometry.set_ease(Tween.EASE_OUT)
		_tween_geometry.set_trans(Tween.TRANS_CUBIC)
		_tween_geometry.tween_property(self, "_displayed_corner_min", c_min, animation_duration)
		_tween_geometry.parallel().tween_property(self, "_displayed_corner_max", c_max, animation_duration)
		_tween_geometry.parallel().tween_method(
			(func(_x: Variant) -> void: _update_geometry()),
			0.0, 1.0, animation_duration
		)
	else:
		_displayed_corner_min = c_min
		_displayed_corner_max = c_max
		_update_geometry()
	
	_corner_min = c_min
	_corner_max = c_max

func _update_geometry() -> void:
	_box_mesh.size = Vector3(_displayed_corner_max - _displayed_corner_min) + Vector3.ONE * margin * 2
	position = (_displayed_corner_min + _displayed_corner_max) / 2

func abort_animation() -> void:
	if _tween_geometry != null:
		_tween_geometry.kill()
		_tween_geometry = null
