class_name EditorDraw
extends EditorBase

var _drawing := false


func on_tool_pressed(cell_pos: Vector3i) ->  void:
	if can_draw_cell_at(cell_pos):
		set_cell_at(cell_pos)
		_drawing = true
		update_preview_visual()
	else:
		pass # fail

func on_tool_moved(cell_pos: Vector3i) ->  void:
	if _drawing:
		if can_draw_cell_at(cell_pos):
			set_cell_at(cell_pos)
	update_preview_visual()

func on_tool_released(_cell_pos: Vector3i) ->  void:
	_drawing = false
	update_preview_visual()

func on_tool_cancelled() ->  void:
	_drawing = false
	update_preview_visual()

func on_color_changed(color: Color) -> void:
	preview_box.color = color

func update_preview_visual() -> void:
	if not can_draw_cell_at(pointed_cell_pos):
		preview_box.hide()
	else:
		var animate := preview_box.visible
		preview_box.show()
		preview_box.set_geometry(pointed_cell_pos, pointed_cell_pos, animate)

func can_draw_cell_at(cell_pos: Vector3i) -> bool:
	const margin := Vector3i.ONE * 12
	# cell_pos is inside (chunk_aabb + margin)
	return (
		voxel_data.is_empty() or
		cell_pos.clamp(
			voxel_data.chunk_aabb_min * voxel_data.chunk_size - margin,
			(voxel_data.chunk_aabb_max + Vector3i.ONE) * voxel_data.chunk_size + margin - Vector3i.ONE
		) == cell_pos
	)
	#return (
		#not voxel_data.has_cell(cell_pos)
		#and (voxel_data.get_neighbors(cell_pos) != VoxelData.NO_NEIGHBOR or voxel_data.is_empty())
	#)

func set_cell_at(cell_pos: Vector3i) -> void:
	voxel_data.set_cell(cell_pos, VoxelData.Cell.new(color_wheel.selected_color()))
	voxel_mesh.update(cell_pos, cell_pos)
