class_name EditorFill
extends EditorBase


var _drawing := false

func on_tool_pressed(cell_pos: Vector3i) ->  void:
	_drawing = true
	if can_propagate_color_from(cell_pos):
		propagate_color_from(cell_pos)
		update_preview_visual()

func on_tool_moved(_cell_pos: Vector3i) ->  void:
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
	if not show_preview(pointed_cell_pos):
		preview_box.hide()
	else:
		var animate := preview_box.visible
		preview_box.show()
		preview_box.set_geometry(pointed_cell_pos, pointed_cell_pos, animate)

func can_propagate_color_from(cell_pos: Vector3i) -> bool:
	var cell := voxel_data.get_cell(cell_pos)
	return (
		cell != null
		and not cell.color.is_equal_approx(color_wheel.selected_color())
	)

func show_preview(cell_pos: Vector3i) -> bool:
	return voxel_data.has_cell(cell_pos)

func propagate_color_from(cell_pos: Vector3i) -> void:
	var cell := voxel_data.get_cell(cell_pos)
	var new_cell := VoxelData.Cell.new(color_wheel.selected_color())
	if cell == null or cell.color.is_equal_approx(new_cell.color):
		return
	var old_color := cell.color
	
	var stack := [cell_pos]
	voxel_data.set_cell(cell_pos, new_cell)
	voxel_mesh.update_material_single(cell_pos)
	
	var imin := cell_pos
	var imax := cell_pos
	
	var p := Perf.new()
	
	while not stack.is_empty():
		cell_pos = stack.pop_back()
		
		for d in VoxelData.side_dir:
			var cp := cell_pos + d
			if voxel_data.get_cell(cp, cell) != null and cell.color.is_equal_approx(old_color):
				voxel_data.set_cell(cp, new_cell)
				voxel_mesh.update_material_single(cp)
				imin = imin.min(cp)
				imax = imax.max(cp)
				stack.push_back(cp)
	
	p.print_delta("fill all")

	#voxel_mesh.update_material(imin, imax)
	#p.print_delta("fill mesh")
