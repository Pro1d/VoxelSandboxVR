class_name VoxelEditor
extends Node3D

@export var enabled := true:
	set(e):
		if enabled != e:
			enabled = e
			tool.enabled = e
			color_picker.enabled = e
			if e:
				_active_editor.enable()
			else:
				_active_editor.disable()
			color_wheel.enabled = e
			tool_wheel.enabled = e

@export var tool : VoxelEditorTool
@export var color_wheel : ColorSelectionWheel
@export var color_picker : ColorPickerTool
@export var tool_wheel : ToolSelectionWheel
@export var transformer_tool : VoxelTransformerTool
@export var secondary_transformer_tool : VoxelTransformerTool

var _editors : Array[EditorBase] = []
var _active_editor : EditorBase

@onready var voxel_mesh := get_parent() as VoxelMesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(tool != null)
	assert(color_picker != null)
	assert(color_wheel != null)
	assert(tool_wheel != null)
	assert(voxel_mesh != null)
	assert(transformer_tool != null)
	
	_editors.resize(VoxelEditorTool.Mode.size())
	for c: EditorBase in get_children():
		if c != null:
			_editors[c.tool_mode] = c
	assert(_editors.all(func(e: EditorBase) -> bool: return e != null))
	
	_active_editor = _editors[tool_wheel.selected_mode()]
	_active_editor.enable()
	
	tool_wheel.mode_selected.connect(_on_tool_mode_changed)
	#transformer_tool.transformed.connect(_on_transformed_by_tool)
	transformer_tool.transformed_decompose.connect(_on_transformed_decompose_by_tool)
	#secondary_transformer_tool.transformed.connect(_on_transformed_by_tool)
	secondary_transformer_tool.transformed_decompose.connect(_on_transformed_decompose_by_tool)

func _on_tool_mode_changed(mode: VoxelEditorTool.Mode) -> void:
	if mode != _active_editor.tool_mode:
		_active_editor.disable()
		_active_editor = _editors[mode]
		if enabled:
			_active_editor.enable()

func _on_transformed_decompose_by_tool(t: Vector3, r: Basis, s: float, ro: Vector3) -> void:
	var ry := Basis.from_euler(Vector3.UP * r.get_euler())
	var old_scale := voxel_mesh.scale.x
	var new_scale := old_scale * s
	var delta_scale := Vector3.ONE * clampf(new_scale, 0.01, 0.10) / old_scale
	voxel_mesh.global_transform = Transform3D(ry.scaled(delta_scale), ro + t) * Transform3D(Basis(), -ro) * voxel_mesh.global_transform
	
	#voxel_mesh.global_position += t
func _on_transformed_by_tool(t: Transform3D) -> void:
	voxel_mesh.global_transform = t * voxel_mesh.global_transform
