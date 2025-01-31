class_name FileItem
extends TextureRect

signal delete_pressed()
signal main_pressed()

const IconOpen := preload("res://assets/textures/white_large/open.png")
const IconSave := preload("res://assets/textures/white_large/save.png")
const IconCreate := preload("res://assets/textures/white_large/create.png")

enum MainButtonMode {
	OPEN, SAVE, CREATE, NONE
}

@onready var _thumbnail_texture := self #%ThumbnailTextureRect as TextureRect
@onready var _darken_rect := %DarkenRect as ColorRect
@onready var _main_button := %MainButton as Button
@onready var _name_label := %NameLabel as Label
@onready var _delete_button := %HoldToPressButton as HoldToPressButton
@onready var _blank_thumbnail := _thumbnail_texture.texture

var main_button_mode : MainButtonMode
var file_base_name : String
var _delete_enabled := true
var _show_details := false
var _mouse_hovered := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_delete_button.hold_pressed.connect(delete_pressed.emit)
	_main_button.pressed.connect(main_pressed.emit)
	
	_thumbnail_texture.mouse_entered.connect(_on_mouse_entered.bind(0b1))
	_thumbnail_texture.mouse_exited.connect(_on_mouse_exited.bind(0b1))
	_delete_button.mouse_entered.connect(_on_mouse_entered.bind(0b10))
	_delete_button.mouse_exited.connect(_on_mouse_exited.bind(0b10))
	_main_button.mouse_entered.connect(_on_mouse_entered.bind(0b100))
	_main_button.mouse_exited.connect(_on_mouse_exited.bind(0b100))
	
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
	match mode:
		MainButtonMode.OPEN:
			_main_button.icon = IconOpen
		MainButtonMode.SAVE:
			_main_button.icon = IconSave
		MainButtonMode.CREATE:
			_main_button.icon = IconCreate
		MainButtonMode.NONE:
			_main_button.icon = null
	
	_update_details()

func enable_delete(e: bool) -> void:
	_delete_enabled = e
	_update_details()

func _on_mouse_entered(flag: int) -> void:
	_mouse_hovered |= flag
	if not _show_details:
		_show_details = true
		_update_details.call_deferred()

func _on_mouse_exited(flag: int) -> void:
	_mouse_hovered &= ~flag
	if _mouse_hovered == 0 and _show_details:
		_show_details = false
		_update_details.call_deferred()

func _update_details() -> void:
	_main_button.visible = _show_details and (main_button_mode != MainButtonMode.NONE) or main_button_mode == MainButtonMode.CREATE
	_delete_button.visible = _show_details and _delete_enabled
	_darken_rect.visible = _show_details
