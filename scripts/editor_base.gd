class_name EditorBase
extends Node3D

@export var tool_mode : VoxelEditorTool.Mode

var enabled := false
var pointed_cell_pos := Vector3i.ZERO

@onready var voxel_editor := get_parent() as VoxelEditor
@onready var preview_box := $PreviewBox as PreviewBox

var tool : VoxelEditorTool:
	get():
		return voxel_editor.tool
var color_wheel : ColorSelectionWheel:
	get():
		return voxel_editor.color_wheel
var voxel_mesh : VoxelMesh:
	get():
		return voxel_editor.voxel_mesh
var voxel_data : VoxelData:
	get():
		return voxel_mesh.voxel_data

func _ready() -> void:
	hide()
	preview_box.hide()

func enable() -> void:
	show()
	enabled = true
	tool.tool_pressed.connect(_on_tool_pressed)
	tool.tool_moved.connect(_on_tool_moved)
	tool.tool_released.connect(_on_tool_released)
	color_wheel.color_changed.connect(on_color_changed)
	pointed_cell_pos = voxel_mesh.global_to_voxel(tool.pointer_position())
	on_color_changed(color_wheel.selected_color())
	update_preview_visual()

func disable() -> void:
	hide()
	enabled = false
	on_tool_cancelled()
	tool.tool_pressed.disconnect(_on_tool_pressed)
	tool.tool_moved.disconnect(_on_tool_moved)
	tool.tool_released.disconnect(_on_tool_released)
	color_wheel.color_changed.disconnect(on_color_changed)
	preview_box.abort_animation()
	preview_box.hide()

func _on_tool_pressed(pos: Vector3) ->  void:
	pointed_cell_pos = voxel_mesh.global_to_voxel(pos)
	on_tool_pressed(pointed_cell_pos)
func on_tool_pressed(_pos: Vector3i) ->  void:
	pass

func _on_tool_moved(pos: Vector3) ->  void:
	pointed_cell_pos = voxel_mesh.global_to_voxel(pos)
	on_tool_moved(pointed_cell_pos)
func on_tool_moved(_pos: Vector3i) ->  void:
	pass

func _on_tool_released(pos: Vector3) ->  void:
	pointed_cell_pos = voxel_mesh.global_to_voxel(pos)
	on_tool_released(pointed_cell_pos)
func on_tool_released(_pos: Vector3i) ->  void:
	pass

func on_tool_cancelled() ->  void:
	pass

func on_color_changed(_color: Color) -> void:
	pass

func update_preview_visual() -> void:
	pass
