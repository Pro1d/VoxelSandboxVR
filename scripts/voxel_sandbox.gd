class_name VoxelSandbox
extends XRToolsSceneBase


var _meta_save : MetaSave

@onready var _camera := %XRCamera3D as XRCamera3D
@onready var _left_controller := %LeftHand as XRController3D
@onready var _right_controller := %RightHand as XRController3D

#@onready var _color_wheel := %ColorSelectionWheel as ColorSelectionWheel
#@onready var _tool_wheel := %ToolSelectionWheel as ToolSelectionWheel
#@onready var _voxel_editor_tool = %VoxelEditerTool as VoxelEditorTool
#@onready var _voxel_transformer_tool = %VoxelTransformerTool as VoxelTransformerTool
#@onready var _voxel_transformer_tool_secondary = %VoxelTransformerToolSecondary as VoxelTransformerTool
#@onready var _color_picker_tool := %ColorPickerTool as ColorPickerTool

@onready var _voxel_mesh := %VoxelMesh as VoxelMesh

@onready var _save_file_ui_3d := %SaveFileManagerUIin3D as XRToolsViewport2DIn3D
@onready var _save_file_manager_ui := %SaveFileManagerUI as SaveFileMangerUI
@onready var _thumbnail_renderer := %ThumbnailRenderer as ThumbnailRenderer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	_save_file_ui_3d.hide()
	_save_file_manager_ui.show_view()
	_left_controller.button_pressed.connect(_on_controller_button_pressed)
	_right_controller.button_pressed.connect(_on_controller_button_pressed)
	_save_file_manager_ui.close_requested.connect(_on_save_file_manager_ui_close_requested)
	_save_file_manager_ui.open_file_requested.connect(_on_save_file_manager_ui_open_file_requested)
	_save_file_manager_ui.file_saved.connect(_on_save_file_manager_ui_file_saved)

func _on_controller_button_pressed(action: String) -> void:
	match action:
		"ax_button":
			if not _save_file_ui_3d.visible:
				if _meta_save == null:
					_meta_save = MetaSave.create()
				var thumbnail := await _thumbnail_renderer.render_voxel(_voxel_mesh, _camera.global_position)
				show_ui_3d(_save_file_ui_3d)
				_save_file_manager_ui.show_save(_voxel_mesh.voxel_data, _meta_save, thumbnail)
		"by_button":
			if not _save_file_ui_3d.visible:
				show_ui_3d(_save_file_ui_3d)
				_save_file_manager_ui.show_open()

func _on_save_file_manager_ui_close_requested() -> void:
	_save_file_ui_3d.hide()

func _on_save_file_manager_ui_file_saved(success: bool) -> void:
	if success:
		_save_file_ui_3d.hide()
	else:
		pass # TODO report error: rumble/sound/message ?

func _on_save_file_manager_ui_open_file_requested(file_base_name: String) -> void:
	_save_file_ui_3d.hide()
	var vd := SFM.load_voxel(file_base_name)
	if vd == null:
		vd = VoxelData.new()
		_meta_save = null
	else:
		_meta_save = SFM.load_meta(file_base_name)
	_voxel_mesh.reset_data(vd)

func show_ui_3d(ui_3d: XRToolsViewport2DIn3D) -> void:
	var camera_ui_offset := ((_camera.global_basis * Vector3.FORWARD) * Vector3(1, 0, 1)).normalized() * 0.6 - Vector3(0, ui_3d.screen_size.y / 2 + 0.2, 0)
	var T := Transform3D(
		Basis(),
		_camera.global_position + camera_ui_offset
	)
	T = T.looking_at(T.origin + camera_ui_offset, Vector3.UP)
	ui_3d.global_transform = T
	ui_3d.show()
