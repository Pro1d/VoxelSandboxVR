class_name EditorPaint
extends EditorBase


var _drawing := false

func on_tool_pressed(cell_pos: Vector3i) ->  void:
	_drawing = true
	if can_set_color_at(cell_pos):
		set_color_at(cell_pos)
		update_preview_visual()

func on_tool_moved(cell_pos: Vector3i) ->  void:
	if _drawing:
		if can_set_color_at(cell_pos):
			set_color_at(cell_pos)
	
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

func can_set_color_at(cell_pos: Vector3i) -> bool:
	var cell := voxel_data.get_cell(cell_pos)
	return (
		cell != null
		and not cell.color.is_equal_approx(color_wheel.selected_color())
	)

func show_preview(cell_pos: Vector3i) -> bool:
	return voxel_data.has_cell(cell_pos)

func set_color_at(cell_pos: Vector3i) -> void:
	var cell := voxel_data.get_cell(cell_pos)
	if cell != null and not cell.color.is_equal_approx(color_wheel.selected_color()):
		voxel_data.set_cell(cell_pos, VoxelData.Cell.new(color_wheel.selected_color()))
		voxel_mesh.update(cell_pos, cell_pos)
