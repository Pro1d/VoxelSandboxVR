class_name FileManagerUI
extends Control

signal open_file_requested(file_base_name: String)
signal file_saved(success: bool)

enum PromptMode { OPEN, SAVE, VIEW }

var _file_items : Array[FileItem] = []
var prompt_mode : PromptMode:
	set(pm):
		prompt_mode = pm
		_update_prompt_mode()

var save_thumbnail : Image
var save_voxel_data : VoxelData
var save_meta : MetaSave

@onready var _file_grid := %FileGrid as Control
@onready var _empty_label := %EmptyLabel as Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for c: FileItem in _file_grid.get_children():
		if c != null:
			c.hide()
			c.delete_pressed.connect(_on_file_delete_pressed.bind(c))
			c.main_pressed.connect(_on_file_main_pressed.bind(c))
			c.visibility_changed.connect(_update_empty) # update on each visibility changed is not the best for performance
			_make_new_file_item(c)
			_file_items.append(c)
	
	if prompt_mode == PromptMode.SAVE:
		_make_new_file_item(_file_items[0])
		_file_items[0].show()
	
	_update_empty()
	_refresh()

##### BEGIN File Manager PUBLIC #####
func show_save(voxel_data: VoxelData, meta: MetaSave, thumbnail: Image) -> void:
	self.prompt_mode = PromptMode.SAVE
	self.save_voxel_data = voxel_data
	self.save_meta = meta
	self.save_thumbnail = thumbnail

func show_open() -> void:
	self.prompt_mode = PromptMode.OPEN
	self.save_voxel_data = null
	self.save_meta = null
	self.save_thumbnail = null

func show_view() -> void:
	self.prompt_mode = PromptMode.VIEW
	self.save_voxel_data = null
	self.save_meta = null
	self.save_thumbnail = null
##### END File Manager PUBLIC #####

func _refresh() -> void:
	SFM.list_files(_file_items.size())
	for i in range(mini(SFM.known_files.size(), _file_items.size())):
		_load_file_item(_file_items[i], SFM.known_files[i])
		_file_items[i].show()
	
	for i in range(SFM.known_files.size(), _file_items.size()):
		_make_new_file_item(_file_items[i])
	
	if prompt_mode == PromptMode.SAVE and SFM.known_files.size() < _file_items.size():
		_file_items[SFM.known_files.size()].show()

func _on_file_delete_pressed(fi: FileItem) -> void:
	_delete(fi)

func _on_file_main_pressed(fi: FileItem) -> void:
	match fi.main_button_mode:
		FileItem.MainButtonMode.OPEN:
			open_file_requested.emit(fi.file_base_name)
		FileItem.MainButtonMode.SAVE, FileItem.MainButtonMode.CREATE:
			_save(fi)

func _make_new_file_item(fi: FileItem) -> void:
	fi.set_base_name("")
	fi.set_caption("New Slot")
	fi.clear_image()
	fi.set_main_button_mode(FileItem.MainButtonMode.CREATE)
	fi.enable_delete(false)
	
func _make_file_item(fi: FileItem, file_base_name: String, meta: MetaSave, thumbnail: Image) -> void:
	fi.set_base_name(file_base_name)
	var caption := file_base_name
	if meta != null:
		caption = meta.modification_date.replace('-', '.').replace('T', ' ')
		caption = caption.substr(0, caption.length() - 3)
	fi.set_caption(caption)
	fi.set_image(thumbnail) #SFM.get_thumbnail_path(file_base_name), 
	fi.set_main_button_mode(_get_main_button_mode())
	fi.enable_delete(true)

func _load_file_item(fi: FileItem, file_base_name: String) -> void:
	var meta := SFM.load_meta(file_base_name)
	var thumbnail := SFM.load_thumbnail(file_base_name)
	_make_file_item(fi, file_base_name, meta, thumbnail)

func _update_prompt_mode() -> void:
	for fi in _file_items:
		if fi != null:
			if fi.main_button_mode == FileItem.MainButtonMode.CREATE:
				fi.hide()
			else:
				fi.set_main_button_mode(_get_main_button_mode())
	
	if prompt_mode == PromptMode.SAVE:
		if SFM.known_files.size() < _file_items.size():
			_make_new_file_item(_file_items[SFM.known_files.size()])
			_file_items[SFM.known_files.size()].show()

func _get_main_button_mode() -> FileItem.MainButtonMode:
	match prompt_mode:
		PromptMode.OPEN:
			return FileItem.MainButtonMode.OPEN
		PromptMode.SAVE:
			return FileItem.MainButtonMode.SAVE
		PromptMode.VIEW, _:
			return FileItem.MainButtonMode.NONE

func _delete(fi: FileItem) -> void:
	# delete file and update view
	SFM.delete_save_files(fi.file_base_name)
	_make_new_file_item(fi)
	fi.hide()
	# move file item to end
	_file_grid.move_child(fi, -1)
	_file_items.erase(fi)
	_file_items.append(fi)

func _save(fi: FileItem) -> void:
	# TODO bad code architecture why saving is implemented here???
	assert(prompt_mode == PromptMode.SAVE)
	assert(not fi.file_base_name.is_empty() or fi.main_button_mode == FileItem.MainButtonMode.CREATE)
	var new_save := fi.file_base_name.is_empty()
	var file_base_name := SFM.next_file_base_name() if new_save else fi.file_base_name
	var success := SFM.write_save_files(file_base_name, save_voxel_data, save_meta, save_thumbnail)
	file_saved.emit(success)
	if not success:
		return
	
	_make_file_item(fi, file_base_name, save_meta, save_thumbnail)
	
	if new_save:
		if SFM.known_files.size() < _file_items.size():
			_make_new_file_item(_file_items[SFM.known_files.size()])
			_file_items[SFM.known_files.size()].show()

func _update_empty() -> void:
	_empty_label.visible = _file_items.all(func(fi: FileItem) -> bool: return not fi.visible)
