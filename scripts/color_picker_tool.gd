class_name ColorPickerTool
extends Node3D

signal color_picked(c: Color)

@export var voxel_mesh : VoxelMesh

var voxel_data : VoxelData:
	get():
		return voxel_mesh.voxel_data

@onready var _controller := get_parent() as XRController3D
@onready var _pointer_node := %PointerMarker3D as Node3D
@onready var _shader := (%MeshInstance3D as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(_controller != null)
	assert(voxel_mesh != null)
	_controller.button_pressed.connect(_on_controller_button_pressed)

func _on_controller_button_pressed(action: String) -> void:
	if action == "trigger_click":
		var cell_pos := voxel_mesh.global_to_voxel(_pointer_node.global_position)
		var cell := voxel_data.get_cell(cell_pos)
		if cell != null:
			color_picked.emit(cell.color)

func _process(_delta: float) -> void:
	var cell_pos := voxel_mesh.global_to_voxel(_pointer_node.global_position)
	var cell := voxel_data.get_cell(cell_pos)
	_shader.set_shader_parameter("paint_color", cell.color if cell != null else Color(0,0,0,0))
