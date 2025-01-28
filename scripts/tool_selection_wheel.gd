class_name ToolSelectionWheel
extends WheelBase

signal mode_selected(mode: VoxelEditorTool.Mode)
#signal mode_triggered(mode: VoxelEditorTool.Mode)

class WheelQuadrant:
	var icon : Texture2D
	var label : String
	var action : VoxelEditorTool.Mode
	var selectable : bool
	func _init(i: Texture2D, l: String, a: VoxelEditorTool.Mode, s: bool) -> void:
		icon = i
		label = l
		action = a
		selectable = s

const IconPen := preload("res://assets/textures/pen.png")
const IconErase := preload("res://assets/textures/eraser.png")
const IconAddBox := preload("res://assets/textures/add_cube.png")
const IconRemoveBox := preload("res://assets/textures/remove_cube.png")
const IconPaint := preload("res://assets/textures/brush2.png")
const IconFill := preload("res://assets/textures/paint-pot.png")

var quadrants : Array[WheelQuadrant] = [
	WheelQuadrant.new(IconPen, "Draw", VoxelEditorTool.Mode.DRAW, true),
	WheelQuadrant.new(IconErase, "Erase", VoxelEditorTool.Mode.ERASE, true),
	WheelQuadrant.new(IconAddBox, "Draw box", VoxelEditorTool.Mode.BOX_DRAW, true),
	WheelQuadrant.new(IconRemoveBox, "Erase box", VoxelEditorTool.Mode.BOX_ERASE, true),
	WheelQuadrant.new(IconFill, "Fill", VoxelEditorTool.Mode.FILL, true),
	WheelQuadrant.new(IconPaint, "Paint", VoxelEditorTool.Mode.PAINT, true),
]

var _selected_quadrant := -1
var _displayed_quadrant_angle := 0.0
var _tween_quadrant_angle : Tween

@onready var ring_shader := ring_mesh.get_surface_override_material(0) as ShaderMaterial
@onready var label_3d := %Label3D as Label3D

func _ready() -> void:
	super()
	label_3d.hide()
	
	# Initialize icons
	var icon_mesh_template := %IconMeshInstance3D as MeshInstance3D
	var mat_template := icon_mesh_template.get_surface_override_material(0)
	for i in range(quadrants.size()):
		var q := quadrants[i]
		var mesh := icon_mesh_template.duplicate() as MeshInstance3D
		var mat := mat_template.duplicate() as StandardMaterial3D
		mesh.position = Vector3(1, 0, 0).rotated(
			Vector3(0, 1, 0), get_angle_from_index(i)
		) * mesh.position.length()
		mat.albedo_texture = q.icon
		mesh.set_surface_override_material(0, mat)
		ring_mesh.add_child(mesh)
		
		if _selected_quadrant < 0 and q.selectable:
			_selected_quadrant = i
			_update_quadrant_highlight(_selected_quadrant, false)
	
	icon_mesh_template.queue_free()
	assert(_selected_quadrant >= 0)
	
	# Initialize ring shader
	var angle_step := 2 * PI / VoxelEditorTool.Mode.size()
	ring_shader.set_shader_parameter("cos_half_quadrant_size", cos(angle_step / 2 * 0.9))
	ring_shader.set_shader_parameter("quadrant_opacity", 1.0)

func selected_mode() -> VoxelEditorTool.Mode:
	return quadrants[_selected_quadrant].action

func _update_quadrant_highlight(quadrant: int, animate: bool) -> void:
	var target_angle := get_angle_from_index(quadrant)
	
	if _tween_quadrant_angle != null:
		_tween_quadrant_angle.kill()
		
	if animate:
		var adiff := angle_difference(_displayed_quadrant_angle, target_angle)
		_displayed_quadrant_angle = wrapf(_displayed_quadrant_angle, 0.0, TAU)
		_tween_quadrant_angle = create_tween()
		_tween_quadrant_angle.tween_method(
			func(angle: float) -> void:
				_displayed_quadrant_angle = angle
				ring_shader.set_shader_parameter("quadrant_direction", Vector2(1, 0).rotated(angle)),
			_displayed_quadrant_angle, _displayed_quadrant_angle + adiff, 0.4) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	else:
		ring_shader.set_shader_parameter("quadrant_direction", Vector2(1, 0).rotated(target_angle))

func _update_label(text: String) -> void:
	label_3d.visible = not text.is_empty()
	label_3d.text = text

func on_pointing_changed(pointed_quadrant: int, __last_pointed_quadrant: int) -> void:
	var q := quadrants[pointed_quadrant]
	_update_quadrant_highlight(pointed_quadrant, true)
	_update_label(q.label)

func on_pointing_exited(last_pointed_quadrant: int) -> void:
	if last_pointed_quadrant >= 0:
		var q := quadrants[last_pointed_quadrant]
		if q.selectable:
			if _selected_quadrant != last_pointed_quadrant:
				_selected_quadrant = last_pointed_quadrant # TODO visual
				mode_selected.emit(q.action)
		#else:
			## non selecteble option: trigger signal on hit
			#mode_triggered.emit(last_pointed_quadrant)
			#if _selected_quadrant != last_pointed_quadrant:
				#_update_quadrant_highlight(_selected_quadrant, false)
	
	_update_label("")
