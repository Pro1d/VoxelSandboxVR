class_name VoxelSandbox
extends XRToolsSceneBase


@onready var _left_controller := %LeftHand as XRController3D
@onready var _right_controller := %RightHand as XRController3D

#@onready var _color_wheel := %ColorSelectionWheel as ColorSelectionWheel
#@onready var _tool_wheel := %ToolSelectionWheel as ToolSelectionWheel
#@onready var _voxel_editor_tool = %VoxelEditerTool as VoxelEditorTool
#@onready var _voxel_transformer_tool = %VoxelTransformerTool as VoxelTransformerTool
#@onready var _voxel_transformer_tool_secondary = %VoxelTransformerToolSecondary as VoxelTransformerTool
#@onready var _color_picker_tool := %ColorPickerTool as ColorPickerTool

@onready var _voxel_mesh := %VoxelMesh as VoxelMesh
@onready var _voxel_editor := %VoxelEditor as VoxelEditor

@onready var _viewport_2d := %Viewport2DIn3D as XRToolsViewport2DIn3D
@onready var _main_ui := %MainUI as MainUI
@onready var _thumbnail_renderer := %ThumbnailRenderer as ThumbnailRenderer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	_viewport_2d.hide()
	_main_ui.close_ui_requested.connect(close_main_ui)
	_left_controller.button_pressed.connect(_on_controller_button_pressed)
	_right_controller.button_pressed.connect(_on_controller_button_pressed)
	Config.thumbnail_renderer = _thumbnail_renderer
	Config.voxel_mesh = _voxel_mesh
	Config.meta_save = null

func _on_controller_button_pressed(action: String) -> void:
	match action:
		"menu_button":
			open_main_ui()

func open_main_ui() -> void:
	_voxel_editor.enabled = false
	_viewport_2d.show()
	_main_ui.show_main_menu()
	
func close_main_ui() -> void:
	_voxel_editor.enabled = true
	_viewport_2d.hide()
