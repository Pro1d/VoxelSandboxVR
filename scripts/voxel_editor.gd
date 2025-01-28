class_name VoxelEditor
extends Node3D

@export var tool : VoxelEditorTool
@export var color_wheel : ColorSelectionWheel
@export var tool_wheel : ToolSelectionWheel
@export var transformer_tool : VoxelTransformerTool
@export var secondary_transformer_tool : VoxelTransformerTool

var _editors : Array[EditorBase] = []
var _active_editor : EditorBase
#var _drawing_region := false
#var _region_start_index := Vector3i.ZERO
#var _region_end_index := Vector3i.ZERO
#var _current_cell_template := VoxelData.Cell.new()

@onready var voxel_mesh := get_parent() as VoxelMesh
#@onready var _preview_mesh := %RegionMesh as MeshInstance3D
#@onready var _preview_box := _preview_mesh.mesh as BoxMesh
#@onready var _preview_mat := _preview_mesh.get_surface_override_material(0) as StandardMaterial3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(tool != null)
	assert(color_wheel != null)
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
		_active_editor.enable()

func _on_transformed_decompose_by_tool(t: Vector3, r: Basis, s: float, ro: Vector3) -> void:
	var ry := Basis.from_euler(Vector3.UP * r.get_euler())
	var old_scale := voxel_mesh.scale.x
	var new_scale := old_scale * s
	var delta_scale := Vector3.ONE * clampf(new_scale, 0.025, 0.20) / old_scale
	voxel_mesh.global_transform = Transform3D(ry.scaled(delta_scale), ro + t) * Transform3D(Basis(), -ro) * voxel_mesh.global_transform
	
	#voxel_mesh.global_position += t
func _on_transformed_by_tool(t: Transform3D) -> void:
	voxel_mesh.global_transform = t * voxel_mesh.global_transform

#func _on_tool_pressed(pos: Vector3) ->  void:
	#match tool.mode:
		#VoxelEditorTool.Mode.DRAW:
			#if can_draw_cell_at(pos):
				#set_cell_at(pos, _current_cell_template)
		#VoxelEditorTool.Mode.ERASE:
			#if can_erase_cell_at(pos):
				#set_cell_at(pos, null)
		#VoxelEditorTool.Mode.BOX_DRAW:
			#if can_start_region(pos):
				#_start_region(pos)
		#VoxelEditorTool.Mode.BOX_ERASE:
			#if can_start_region(pos):
				#_start_region(pos)
		#VoxelEditorTool.Mode.PAINT:
			#if can_set_color_at(pos, _current_cell_template):
				#set_color_at(pos, _current_cell_template)
		#VoxelEditorTool.Mode.FILL:
			#if can_propagate_color_from(pos, _current_cell_template):
				#propagate_color_from(pos, _current_cell_template)
#
#func _on_tool_moved(pos: Vector3) ->  void:
	#if tool.pressed:
		#match tool.mode:
			#VoxelEditorTool.Mode.DRAW:
				#if can_draw_cell_at(pos):
					#set_cell_at(pos, _current_cell_template)
			#VoxelEditorTool.Mode.ERASE:
				#if can_erase_cell_at(pos):
					#set_cell_at(pos, null)
			#VoxelEditorTool.Mode.BOX_DRAW:
				#if _drawing_region:
					#_update_region(pos)
			#VoxelEditorTool.Mode.BOX_ERASE:
				#if _drawing_region:
					#_update_region(pos)
			#VoxelEditorTool.Mode.PAINT:
				#if can_set_color_at(pos, _current_cell_template):
					#set_color_at(pos, _current_cell_template)
			#VoxelEditorTool.Mode.FILL:
				#if can_propagate_color_from(pos, _current_cell_template):
					#propagate_color_from(pos, _current_cell_template)
	#_update_region_visual()
#
#func _on_tool_released(_pos: Vector3) ->  void:
	#match tool.mode:
		#VoxelEditorTool.Mode.BOX_DRAW:
			#_draw_region(_current_cell_template)
			#_clear_region()
		#VoxelEditorTool.Mode.BOX_ERASE:
			#_erase_region()
			#_clear_region()
#
#func _on_tool_cancelled() ->  void:
	#match tool.mode:
		#VoxelEditorTool.Mode.BOX_DRAW, VoxelEditorTool.Mode.BOX_ERASE:
			#_clear_region()
#
#func _on_color_changed(color: Color) -> void:
	#_current_cell_template.color = color
	#_update_region_visual()
#
#func can_set_color_at(pos: Vector3, c: VoxelData.Cell) -> bool:
	#var cell_pos := voxel_mesh.global_to_voxel(pos)
	#var cell := voxel_mesh.voxel_data.get_cell(cell_pos)
	#return (
		#cell != null
		#and not cell.color.is_equal_approx(c.color)
	#)
#
#func set_color_at(pos: Vector3, c: VoxelData.Cell) -> void:
	#var cell_pos := voxel_mesh.global_to_voxel(pos)
	#var cell := voxel_mesh.voxel_data.get_cell(cell_pos)
	#if cell != null and not cell.color.is_equal_approx(c.color):
		#voxel_mesh.voxel_data.set_cell(cell_pos, c)
		#voxel_mesh.update(cell_pos, cell_pos)
#
#func can_propagate_color_from(pos: Vector3, c: VoxelData.Cell) -> bool:
	#return can_set_color_at(pos, c)
#
#func propagate_color_from(pos: Vector3, c: VoxelData.Cell) -> void:
	#var cell_pos := voxel_mesh.global_to_voxel(pos)
	#var cell := voxel_mesh.voxel_data.get_cell(cell_pos)
	#if cell == null or cell.color.is_equal_approx(c.color):
		#return
	#var old_color := cell.color
	#var stack := [cell_pos]
	#var imin := cell_pos
	#var imax := cell_pos
	#while not stack.is_empty():
		#cell_pos = stack.pop_back()
		#cell = voxel_mesh.voxel_data.get_cell(cell_pos)
		#if cell.color.is_equal_approx(old_color):
			#voxel_mesh.voxel_data.set_cell(cell_pos, c)
			#imin = imin.min(cell_pos)
			#imax = imin.max(cell_pos)
			#for d in VoxelData.side_dir:
				#if voxel_mesh.voxel_data.has_cell(cell_pos + d):
					#stack.push_back(cell_pos + d)
	#
	#voxel_mesh.update(imin, imax)
#
#func can_draw_cell_at(pos: Vector3) -> bool:
	#var cell_pos := voxel_mesh.global_to_voxel(pos)
	#return (
		#not voxel_mesh.voxel_data.has_cell(cell_pos)
		#and voxel_mesh.voxel_data.get_neighbors(cell_pos) != VoxelData.NO_NEIGHBOR
	#)
#
#func set_cell_at(pos: Vector3, c: VoxelData.Cell) -> void:
	#var cell_pos := voxel_mesh.global_to_voxel(pos)
	#voxel_mesh.voxel_data.set_cell(cell_pos, c)
	#voxel_mesh.update(cell_pos, cell_pos)
#
#func can_erase_cell_at(pos: Vector3) -> bool:
	#var cell_pos := voxel_mesh.global_to_voxel(pos)
	#return (
		#voxel_mesh.voxel_data.has_cell(cell_pos)
		#and voxel_mesh.voxel_data.get_neighbors(cell_pos) != VoxelData.ALL_NEIGHBORS
	#)
#
#func clear_cell_at(pos: Vector3) -> void:
	#var cell_pos := voxel_mesh.global_to_voxel(pos)
	#voxel_mesh.voxel_data.set_cell(cell_pos, null)
	#voxel_mesh.update(cell_pos, cell_pos)
#
#func _draw_region(c: VoxelData.Cell) -> void:
	#assert(_drawing_region)
	#var imin := _region_start_index.min(_region_end_index)
	#var imax := _region_start_index.max(_region_end_index)
	#voxel_mesh.voxel_data.fill_cells(imin, imax, c)
	#voxel_mesh.update(imin, imax)
#
#func _erase_region() -> void:
	#assert(_drawing_region)
	#var imin := _region_start_index.min(_region_end_index)
	#var imax := _region_start_index.max(_region_end_index)
	#voxel_mesh.voxel_data.fill_cells(imin, imax, null)
	#voxel_mesh.update(imin, imax)
#
#func can_start_region(_pos: Vector3) -> bool:
	#return true
#
#func _start_region(pos: Vector3) -> void:
	#_drawing_region = true
	#_region_start_index = voxel_mesh.global_to_voxel(pos)
	#_region_end_index = _region_start_index
	#_update_region_visual()
#
#func _update_region(pos: Vector3) -> void:
	#assert(_drawing_region)
	#_region_end_index = voxel_mesh.global_to_voxel(pos)
	#_update_region_visual()
#
#func _clear_region() -> void:
	#_drawing_region = false
	#_update_region_visual()
#
#func _update_region_visual() -> void:
	#if _drawing_region:
		#_preview_mesh.show()
		#var margin := Vector3.ZERO
		#var color := _current_cell_template.color
		#match tool.mode:
			#VoxelEditorTool.Mode.BOX_ERASE:
				#color = Color(0.5, 0.1, 0.0, 0.4)
				#margin = Vector3.ONE * 0.05
			#VoxelEditorTool.Mode.BOX_DRAW:
				#color = Color(0.5, 0.1, 0.0, 0.4)
				#margin = -Vector3.ONE * 0.01
		#_preview_box.size = Vector3((_region_start_index - _region_start_index).abs() + Vector3i.ONE) - margin * 2
		#_preview_mesh.position = (Vector3(_region_start_index + _region_start_index) +  Vector3.ONE) / 2
		#_preview_mat.albedo_color = color
	#else:
		#_preview_mesh.hide()
#
#func _update_active_cell_visual() -> void:
	#pass
