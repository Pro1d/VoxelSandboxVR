class_name SaveFileManager
extends Node

const ROOT_DIR := "user://saves"
const VOXEL_EXT := ".voxel.res"
const META_EXT := ".meta.tres"
const THUMB_EXT := ".thumb.png"

## file base names, sorted
var known_files : Array[String] = []
var _highest_free_integer := 0

func ensure_ROOT_DIR() -> void:
	if not DirAccess.dir_exists_absolute(ROOT_DIR):
		DirAccess.make_dir_absolute(ROOT_DIR)

func list_files(max_count: int) -> void:
	ensure_ROOT_DIR()
	
	_highest_free_integer = 0
	known_files.clear()
	
	for p in DirAccess.get_files_at(ROOT_DIR):
		if p.ends_with(VOXEL_EXT):
			var file_name := p.get_file()
			var file_base_name := file_name.substr(file_name.length() - VOXEL_EXT.length())
			known_files.append(file_base_name)
			_highest_free_integer = maxi(_highest_free_integer, get_integer_from_file_base_name(file_base_name) + 1)
			
	known_files.resize(mini(known_files.size(), max_count))
	print(known_files)
	known_files = ["0001", "0002"]

func delete_save_files(file_base_name: String) -> void:
	ensure_ROOT_DIR()
	var res : int
	
	var v := get_voxel_path(file_base_name)
	res = DirAccess.remove_absolute(v) 
	if res != OK: printerr("(", res, ") error removing voxel file.")
	
	var t := get_thumbnail_path(file_base_name)
	res = DirAccess.remove_absolute(t)
	if res != OK: printerr("(", res, ") error removing thumbnail file.")
	
	var m := get_meta_path(file_base_name)
	res = DirAccess.remove_absolute(m)
	if res != OK: printerr("(", res, ") error removing meta file.")
	
	known_files.erase(file_base_name)

func next_file_base_name() -> String:
	var file_base_name := make_file_base_name(_highest_free_integer)
	_highest_free_integer += 1
	return file_base_name

func write_save_files(file_base_name: String, voxel_data: VoxelData, meta: MetaSave, image: Image) -> bool:
	ensure_ROOT_DIR()
	var res : int
	
	var v := get_voxel_path(file_base_name)
	res = ResourceSaver.save(voxel_data, v, ResourceSaver.FLAG_COMPRESS)
	if res != OK:
		printerr("(", res, ") error writing voxel file. Abort writing.")
		return false
	
	var m := get_meta_path(file_base_name)
	res = ResourceSaver.save(meta, m)
	if res != OK: printerr("(", res, ") error writing meta file.")
	
	var t := get_thumbnail_path(file_base_name)
	res = image.save_png(t)
	if res != OK: printerr("(", res, ") error writing thumbnail file.")
	
	if not known_files.has(file_base_name):
		known_files.append(file_base_name)
	return true

func load_thumbnail(file_base_name: String) -> Image:
	return Image.load_from_file(get_thumbnail_path(file_base_name))

func load_meta(file_base_name: String) -> MetaSave:
	return ResourceLoader.load(get_meta_path(file_base_name)) as MetaSave

func load_voxel(file_base_name: String) -> VoxelData:
	return ResourceLoader.load(get_meta_path(file_base_name)) as VoxelData

func make_file_base_name(index: int) -> String:
	return "%04d" % [index]

func get_integer_from_file_base_name(file_base_name: String) -> int:
	var n := file_base_name.trim_prefix("0")
	if n.is_valid_int():
		return n.to_int()
	else:
		return -1

func get_voxel_path(file_base_name: String) -> String:
	return ROOT_DIR.path_join(file_base_name) + VOXEL_EXT

func get_thumbnail_path(file_base_name: String) -> String:
	return ROOT_DIR.path_join(file_base_name) + THUMB_EXT

func get_meta_path(file_base_name: String) -> String:
	return ROOT_DIR.path_join(file_base_name) + META_EXT

func CLEAR_ALL() -> void:
	for p in DirAccess.get_files_at(ROOT_DIR):
		DirAccess.remove_absolute(p)
	known_files.clear()
