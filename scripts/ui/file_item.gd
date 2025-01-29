class_name FileItem
extends TextureRect

signal delete_pressed()
signal main_pressed()

const IconOpen := preload("res://assets/textures/large_open.png")
const IconSave := preload("res://assets/textures/large_save.png")
const IconCreate := preload("res://assets/textures/large_create.png")

enum MainButtonMode {
	OPEN, SAVE, CREATE, NONE
}

@onready var _thumbnail_texture := self
@onready var _darken_rect := %DarkenRect as ColorRect
@onready var _main_button := %TextureButton as TextureButton
@onready var _name_label := %NameLabel as Label
@onready var _delete_button := %HoldToPressButton as HoldToPressButton
@onready var _blank_thumbnail := _thumbnail_texture.texture

var main_button_mode : MainButtonMode
var file_base_name : String
var _delete_enabled := true
var _show_details := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_delete_button.hold_pressed.connect(delete_pressed.emit)
	_main_button.pressed.connect(main_pressed.emit)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	set_main_button_mode(MainButtonMode.OPEN)

func set_base_name(fbn: String) -> void:
	file_base_name = fbn

func set_caption(caption: String) -> void:
	_name_label.text = caption

func clear_image() -> void:
	_thumbnail_texture.texture = _blank_thumbnail

func load_image_async(path: String) -> void:
	# TODO async 
	set_image(Image.load_from_file(path))

func set_image(image: Image) -> void:
	if image != null:
		_thumbnail_texture.texture = ImageTexture.create_from_image(image)
	else:
		clear_image()

func set_main_button_mode(mode: MainButtonMode) -> void:
	main_button_mode = mode
	var tex : Texture2D
	match mode:
		MainButtonMode.OPEN:
			tex = IconOpen
		MainButtonMode.SAVE:
			tex = IconSave
		MainButtonMode.CREATE:
			tex = IconCreate
		MainButtonMode.NONE:
			tex = null
	
	_main_button.texture_normal = tex
	_main_button.texture_hover = tex
	_main_button.texture_pressed = tex
	_update_details()

func enable_delete(e: bool) -> void:
	_delete_enabled = e
	_update_details()

func _on_mouse_entered() -> void:
	_show_details = true
	_update_details()

func _on_mouse_exited() -> void:
	_show_details = false
	_update_details()

func _update_details() -> void:
	_main_button.visible = _show_details and (main_button_mode != MainButtonMode.NONE)
	_delete_button.visible = _show_details and _delete_enabled
	_darken_rect.visible = _show_details
