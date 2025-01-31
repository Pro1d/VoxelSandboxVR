class_name ButtonHint
extends Node3D

enum Side { LEFT, RIGHT, TOP, BOTTOM }


const MAX_CAMERA_ANGLE := deg_to_rad(30)
const MAX_ORIENTATION_ANGLE := deg_to_rad(30)

@export var icon : Texture2D = preload("res://assets/textures/white/menu.png")
@export var label := "Menu"
@export var label_side := Side.LEFT
@export_node_path("Node3D") var camera : NodePath

var _camera_node : Node3D

@onready var _mesh := %MeshInstance3D as MeshInstance3D
@onready var _shader := _mesh.get_surface_override_material(0) as ShaderMaterial
@onready var _label := %Label3D as Label3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_label.text = label
	_label.visible = false
	var offset := _label.offset.length()
	match label_side:
		Side.LEFT:
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_label.offset = Vector2(-offset, 0)
		Side.RIGHT:
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_label.offset = Vector2(offset, 0)
		Side.TOP:
			_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			_label.offset = Vector2(0, offset)
		Side.BOTTOM:
			_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			_label.offset = Vector2(0, -offset)
	_shader.set_shader_parameter("texture_albedo", icon)
	(func() -> void: _camera_node = get_node(camera)).call_deferred()

func _process(_delta: float) -> void:
	if _camera_node != null:
		var self_dir := global_basis.y
		var look_dir := -_camera_node.global_basis.z
		var dir := global_position - _camera_node.global_position
		_label.visible = (
			look_dir.angle_to(dir) < MAX_CAMERA_ANGLE
			and self_dir.angle_to(-dir) < MAX_ORIENTATION_ANGLE
		)
