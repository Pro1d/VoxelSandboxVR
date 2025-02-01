class_name EditorBoxErase
extends EditorBase

const MAX_BOX_VOLUME := 512 # cells^3 ; 8x8x8 or 512x1x1 or 64x4x2 or ...

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
		_box_end_index = _clamped_box_end_index()
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
	var p := Perf.new()
	voxel_data.fill_cells(imin, imax, null)
	p.print_delta("box_erase data")
	#voxel_mesh.update(imin, imax)
	voxel_mesh.update_fill_box(imin, imax, null)
	p.print_delta("box_erase mesh")

func can_start_draw_box(cell_pos: Vector3i) -> bool:
	const margin := Vector3i.ONE * 8
	# cell_pos is inside (chunk_aabb + margin)
	return (
		voxel_data.is_empty() or
		cell_pos.clamp(
			voxel_data.chunk_aabb_min * voxel_data.chunk_size - margin,
			(voxel_data.chunk_aabb_max + Vector3i.ONE) * voxel_data.chunk_size + margin - Vector3i.ONE
		) == cell_pos
	)
	#return true

## return _box_end_index clamped so the box volume does not exceed MAX_BOX_VOLUME
func _clamped_box_end_index() -> Vector3i:
	var clamped_end_index := _box_end_index
	var desired_size := (_box_end_index - _box_start_index).abs() + Vector3i.ONE
	var desired_volume := desired_size.x * desired_size.y * desired_size.z
	
	if desired_volume > MAX_BOX_VOLUME:
		var allowed_size := Vector3(desired_size) * MAX_BOX_VOLUME / desired_volume
		var adjusted_size : Vector3i
		
		if allowed_size.x < 1.0:
			if allowed_size.y < 1.0:
				adjusted_size.x = 1
				adjusted_size.y = 1
				adjusted_size.z = MAX_BOX_VOLUME
			elif allowed_size.z < 1.0:
				adjusted_size.x = 1
				adjusted_size.y = MAX_BOX_VOLUME
				adjusted_size.z = 1
			else:
				adjusted_size.x = 1
				adjusted_size.y = int(allowed_size.y * sqrt(allowed_size.x))
				adjusted_size.z = int(allowed_size.z * sqrt(allowed_size.x))
		elif allowed_size.y < 1.0:
			if allowed_size.z < 1.0:
				adjusted_size.x = MAX_BOX_VOLUME
				adjusted_size.y = 1
				adjusted_size.z = 1
			else:
				adjusted_size.x = int(allowed_size.x * sqrt(allowed_size.y))
				adjusted_size.y = 1
				adjusted_size.z = int(allowed_size.z * sqrt(allowed_size.y))
		elif allowed_size.z < 1.0:
			adjusted_size.x = int(allowed_size.x * sqrt(allowed_size.z))
			adjusted_size.y = int(allowed_size.y * sqrt(allowed_size.z))
			adjusted_size.z = 1
		else:
			adjusted_size = Vector3i(allowed_size)
		
		var size_sign := (_box_end_index - _box_start_index).sign()
		clamped_end_index = _box_start_index + (adjusted_size - Vector3i.ONE) * size_sign

	return clamped_end_index
