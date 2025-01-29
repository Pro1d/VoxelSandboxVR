class_name SaveFileMangerUI
extends PanelContainer

signal close_requested()
signal open_file_requested(file_base_name: String)
signal file_saved()

@onready var _title_label := %TitleLabel as Label
@onready var _close_button := %CloseButton as Button
@onready var _file_grid := %FileGrid as FileGrid

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_close_button.pressed.connect(close_requested.emit)
	_file_grid.open_file_requested.connect(open_file_requested.emit)
	_file_grid.file_saved.connect(file_saved.emit)
	_file_grid._refresh()
	show_open()

func show_save(voxel_data: VoxelData, meta: MetaSave, thumbnail: Image) -> void:
	_title_label.text = "Save Model"
	_close_button.text = "Cancel"
	_file_grid.prompt_mode = FileGrid.PromptMode.SAVE
	_file_grid.save_voxel_data = voxel_data
	_file_grid.save_meta = meta
	_file_grid.save_thumbnail = thumbnail

func show_open() -> void:
	_title_label.text = "Open Model"
	_close_button.text = "Cancel"
	_file_grid.prompt_mode = FileGrid.PromptMode.OPEN
	_file_grid.save_voxel_data = null
	_file_grid.save_meta = null
	_file_grid.save_thumbnail = null

func show_view() -> void:
	_title_label.text = "My Models"
	_close_button.text = "Close"
	_file_grid.prompt_mode = FileGrid.PromptMode.VIEW
	_file_grid.save_voxel_data = null
	_file_grid.save_meta = null
	_file_grid.save_thumbnail = null
