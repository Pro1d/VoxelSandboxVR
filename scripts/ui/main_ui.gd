class_name MainUI
extends VBoxContainer

signal close_ui_requested

@onready var _file_manager_ui := $FileManagerUI as FileManagerUI
@onready var _main_menu := $MainMenu as MainMenu
@onready var _bottom_bar := $BottomBar as BottomBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_main_menu.button_clicked.connect(
		func(b: MainMenu.ButtonType) -> void:
			match b:
				MainMenu.ButtonType.OPEN:
					show_open()
				MainMenu.ButtonType.SAVE:
					show_save()
				MainMenu.ButtonType.SETTINGS:
					_show(null, "Settings")
				MainMenu.ButtonType.NEW:
					pass # start blank voxel
	)
	_bottom_bar.back_clicked.connect(_on_back_clicked)
	_bottom_bar.close_clicked.connect(close_ui_requested.emit)
	_file_manager_ui.open_file_requested.connect(_on_open_file_requested)
	_file_manager_ui.file_saved.connect(close_ui_requested.emit)

func _on_back_clicked() -> void:
	show_main_menu()

func show_main_menu() -> void:
	_show(_main_menu, "Main Menu")

func show_open() -> void:
	_file_manager_ui.show_open()
	_show(_file_manager_ui, "Open Model")

func show_save() -> void:
	if Config.meta_save == null:
		Config.meta_save = MetaSave.create()
	# TODO bad code architecture why saving is implemented here and in FileManagerUI???
	var thumbnail := await Config.thumbnail_renderer.render_voxel()
	_show(_file_manager_ui, "Save Model")
	_file_manager_ui.show_save(Config.voxel_mesh.voxel_data, Config.meta_save, thumbnail)

func _show(page: Control, title: String) -> void:
	_file_manager_ui.visible = (page == _file_manager_ui)
	_main_menu.visible = (page == _main_menu)
	var allow_back := page != _main_menu
	_bottom_bar.set_content(title, allow_back, true)

func _on_open_file_requested(file_base_name: String) -> void:
	var vd := SFM.load_voxel(file_base_name)
	if vd == null:
		pass # TODO report error: rumble/sound/message ?
	else:
		Config.meta_save = SFM.load_meta(file_base_name)
		Config.voxel_mesh.reset_data(vd)
		close_ui_requested.emit()

func _on_create_file_file_requested() -> void:
	Config.meta_save = null
	Config.voxel_mesh.reset_data(null)
	close_ui_requested.emit()
