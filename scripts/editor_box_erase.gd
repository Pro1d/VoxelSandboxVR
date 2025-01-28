class_name EditorBoxErase
extends EditorBase


var _drawing := false
var _box_start_index := Vector3i.ZERO
var _box_end_index := Vector3i.ZERO

func on_tool_pressed(cell_pos: Vector3i) ->  void:
	if can_start_draw_box(cell_pos):
		_box_start_index = cell_pos
		_box_end_index = cell_pos
		_drawing = true
		update_preview_visual()
	else:
		pass # fail

func on_tool_moved(cell_pos: Vector3i) ->  void:
	if _drawing:
		_box_end_index = cell_pos
		update_preview_visual()
	else:
		update_preview_visual()

func on_tool_released(_cell_pos: Vector3i) ->  void:
	if _drawing:
		erase_box()
		_drawing = false
		update_preview_visual()

func on_tool_cancelled() ->  void:
	_drawing = false
	update_preview_visual()

var _was_drawing := false
func update_preview_visual() -> void:
	if _drawing:
		var animate := preview_box.visible and _was_drawing
		preview_box.show()
		preview_box.set_geometry(_box_start_index, _box_end_index, animate)
		preview_box.opacity = 1.0
	elif can_start_draw_box(pointed_cell_pos):
		var animate := preview_box.visible and not _was_drawing
		preview_box.show()
		preview_box.set_geometry(pointed_cell_pos, pointed_cell_pos, animate)
		preview_box.opacity = 0.5
	else:
		preview_box.hide()
	_was_drawing = _drawing

func erase_box() -> void:
	assert(_drawing)
	var imin := _box_start_index.min(_box_end_index)
	var imax := _box_start_index.max(_box_end_index)
	voxel_data.fill_cells(imin, imax, null)
	voxel_mesh.update(imin, imax)

func can_start_draw_box(cell_pos: Vector3i) -> bool:
	const margin := Vector3i.ONE * 12
	# cell_pos is inside (chunk_aabb + margin)
	return (
		voxel_data.is_empty() or
		cell_pos.clamp(
			voxel_data.chunk_aabb_min * VoxelData.CHUNK_SIZE - margin,
			(voxel_data.chunk_aabb_max + Vector3i.ONE) * VoxelData.CHUNK_SIZE + margin - Vector3i.ONE
		) == cell_pos
	)
	#return true
