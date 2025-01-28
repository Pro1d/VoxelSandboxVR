class_name ColorSelectionWheel
extends WheelBase

signal color_changed(c: Color)

@export var color_picker_tool : ColorPickerTool
@export var colors : Array[Color]

var _displayed_quadrant_angle := 0.0
var _tween_quadrant_angle : Tween
var _selected_quadrant := 0

@onready var ring_shader := ring_mesh.get_surface_override_material(0) as ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	quadrant_count = colors.size()
	
	# Generate color map
	var image := Image.create_empty(colors.size(), 1, false, Image.Format.FORMAT_RGB8)
	for i in range(colors.size()):
		colors[i] = VoxelData.Cell.from_u16(VoxelData.Cell.to_u16(VoxelData.Cell.new(colors[i]))).color
		image.set_pixel(i, 0, colors[i])
	var texture := ImageTexture.create_from_image(image)
	
	ring_shader.set_shader_parameter("color_palette", texture)
	
	_update_quadrant_highlight(_selected_quadrant, false)
	
	if color_picker_tool != null:
		color_picker_tool.color_picked.connect(_on_color_picked)

func on_pointing_changed(pointed_quadrant: int, __last_pointed_quadrant: int) -> void:
	_update_quadrant_highlight(pointed_quadrant, true)
	_selected_quadrant = pointed_quadrant
	color_changed.emit(selected_color())

func _update_quadrant_highlight(quadrant: int, animate: bool) -> void:
	var target_angle := get_angle_from_index(quadrant)
	
	if _tween_quadrant_angle != null:
		_tween_quadrant_angle.kill()
		
	if animate:
		var adiff := angle_difference(_displayed_quadrant_angle, target_angle)
		_displayed_quadrant_angle = fposmod(_displayed_quadrant_angle, TAU)
		_tween_quadrant_angle = create_tween()
		_tween_quadrant_angle.tween_method(
			func(angle: float) -> void:
				_displayed_quadrant_angle = angle
				ring_shader.set_shader_parameter("quadrant_angle", angle),
			_displayed_quadrant_angle, _displayed_quadrant_angle + adiff, 0.25) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	else:
		ring_shader.set_shader_parameter("quadrant_angle", target_angle)

func selected_color() -> Color:
	return colors[_selected_quadrant]

func _on_color_picked(color: Color) -> void:
	for i in range(colors.size()):
		if colors[i].is_equal_approx(color):
			_selected_quadrant = i
			_update_quadrant_highlight(_selected_quadrant, true)
			color_changed.emit(selected_color())
			break
