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
					_on_create_file_file_requested()
	)
	_bottom_bar.back_clicked.connect(_on_back_clicked)
	_bottom_bar.close_clicked.connect(close_ui_requested.emit)
	_file_manager_ui.open_file_requested.connect(_on_open_file_requested)
	#_file_manager_ui.file_saved.connect(_on_file_saved)
	SoundFxManager.connect_all_buttons(self)

func _on_back_clicked() -> void:
	show_main_menu()

#func _on_file_saved(success: bool) -> void:
	#if success:
		#close_ui_requested.emit()

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
		Config.voxel_mesh.global_transform = _make_voxel_transform(vd, Config.camera.global_transform, Config.voxel_mesh.default_scale)
		close_ui_requested.emit()

func _on_create_file_file_requested() -> void:
	Config.meta_save = null
	Config.voxel_mesh.reset_data(VoxelData.new())
	Config.voxel_mesh.global_transform = _make_voxel_transform(null, Config.camera.global_transform, Config.voxel_mesh.default_scale)
	close_ui_requested.emit()

func _make_voxel_transform(vd: VoxelData, view_transform: Transform3D, s: Vector3) -> Transform3D:
	var aabb_size := (Vector3(vd.chunk_aabb_max+Vector3i.ONE - vd.chunk_aabb_min) * vd.chunk_size if vd != null else Vector3.ZERO) * s
	var heading := view_transform.basis.get_euler().y
	var view_to_voxel_offset := Vector3.FORWARD.rotated(Vector3.UP, heading) * (aabb_size.z / 2 + 0.30)
	var transform := view_transform.looking_at(
		view_transform.origin + view_to_voxel_offset,
		Vector3.UP
	).scaled_local(s).translated(view_to_voxel_offset)
	
	# adjust height
	transform.origin.y = maxf(
		transform.origin.y - 0.05 - aabb_size.y / 2, # model top is 0.05 m below player head (desired)
		aabb_size.y / 2 # model bottom is above ground (required)
	)
	var aabb_center := (Vector3(vd.chunk_aabb_max+Vector3i.ONE + vd.chunk_aabb_min) / 2 * vd.chunk_size if vd != null else Vector3.ZERO)
	return transform.translated_local(-aabb_center)
