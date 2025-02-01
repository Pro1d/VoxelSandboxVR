class_name EditorErase
extends EditorBase

var _drawing := false


func on_tool_pressed(cell_pos: Vector3i) ->  void:
	if can_erase_cell_at(cell_pos):
		erase_cell_at(cell_pos)
	else:
		pass # fail
	_drawing = true
	update_preview_visual()

func on_tool_moved(cell_pos: Vector3i) ->  void:
	if _drawing:
		if can_erase_cell_at(cell_pos):
			erase_cell_at(cell_pos)
	update_preview_visual()

func on_tool_released(_cell_pos: Vector3i) ->  void:
	_drawing = false
	update_preview_visual()

func on_tool_cancelled() ->  void:
	_drawing = false
	update_preview_visual()

func update_preview_visual() -> void:
	if _drawing or not can_erase_cell_at(pointed_cell_pos):
		preview_box.hide()
	else:
		var animate := preview_box.visible
		preview_box.show()
		preview_box.set_geometry(pointed_cell_pos, pointed_cell_pos, animate)

func can_erase_cell_at(cell_pos: Vector3i) -> bool:
	return (
		voxel_mesh.voxel_data.has_cell(cell_pos)
		#and voxel_mesh.voxel_data.get_neighbors(cell_pos) != VoxelData.ALL_NEIGHBORS
	)

func erase_cell_at(cell_pos: Vector3i) -> void:
	voxel_mesh.voxel_data.set_cell(cell_pos, null)
	voxel_mesh.update(cell_pos, cell_pos)
