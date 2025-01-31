class_name VoxelData
extends Resource

const CURRENT_VERSION := 0
const CHUNK_SIZE := 4 # cell
const CELL_BUFFER_SIZE := 2 # Bytes
const CHUNK_BUFFER_SIZE := CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE * CELL_BUFFER_SIZE
const ALL_NEIGHBORS := 0b111111
const NO_NEIGHBOR := 0b000000

enum Side { XP, XM, YP, YM, ZP, ZM };
const side_dir: Array[Vector3i] = [
	Vector3(1, 0, 0),
	Vector3(-1, 0, 0),
	Vector3(0, 1, 0),
	Vector3(0, -1, 0),
	Vector3(0, 0, 1),
	Vector3(0, 0, -1)
]

class Cell:
	# cell (u16) = type_enum(4) r(4) g(4) b(4)
	#   --> type_enum { EMPTY = 0, DEFAULT (FLAT?)=1, ... transparent, material... }
	var color : Color
	func _init(c: Color = Color()) -> void:
		if c != null:
			color = c
		
	static func is_cell(u16: int) -> bool:
		return ((u16 & 0b1111) != 0)
	
	static func from_u16(u16: int) -> Cell:
		var cell : Cell = null
		if Cell.is_cell(u16):
			cell = Cell.new()
			cell.color.r8 = (((u16 >> 4) & 0b1111) * 0b00010001)
			cell.color.g8 = (((u16 >> 8) & 0b1111) * 0b00010001)
			cell.color.b8 = (((u16 >> 12) & 0b1111) * 0b00010001)
		return cell
	
	static func to_u16(cell: Cell) -> int:
		var u16 := 0
		if cell != null:
			u16 = 0x0001
			u16 |= (cell.color.r8 & 0b11110000)
			u16 |= (cell.color.g8 & 0b11110000) << 4
			u16 |= (cell.color.b8 & 0b11110000) << 8
		return u16

@export var version := CURRENT_VERSION
@export var chunks : Dictionary  # Dict[Vector3i, PackedByteArray]

@export var chunk_aabb_min : Vector3i
@export var chunk_aabb_max : Vector3i

static func get_chunk_index(cell_pos: Vector3i) -> Vector3i:
	return (cell_pos - get_cell_index(cell_pos)) / CHUNK_SIZE

static func get_cell_index(cell_pos: Vector3i) -> Vector3i:
	return Vector3i(
		posmod(cell_pos.x, CHUNK_SIZE),
		posmod(cell_pos.y, CHUNK_SIZE),
		posmod(cell_pos.z, CHUNK_SIZE),
	)

static func get_cell_offset(cell_index: Vector3i) -> int:
	return cell_index.x + CHUNK_SIZE * (cell_index.y + CHUNK_SIZE * cell_index.z)

func is_empty() -> bool:
	return chunks.is_empty()

func get_cell(cell_pos: Vector3i) -> Cell:
	var chunk_index := VoxelData.get_chunk_index(cell_pos)
	var chunk : Variant = chunks.get(chunk_index)
	
	var cell : Cell = null
	if chunk is PackedByteArray:
		var cell_index := VoxelData.get_cell_index(cell_pos)
		var offset := VoxelData.get_cell_offset(cell_index)
		var u16 := (chunk as PackedByteArray).decode_u16(offset * CELL_BUFFER_SIZE)
		cell = Cell.from_u16(u16)
	
	return cell

func has_cell(cell_pos: Vector3i) -> bool:
	var chunk_index := VoxelData.get_chunk_index(cell_pos)
	var chunk : Variant = chunks.get(chunk_index)
	
	if chunk is PackedByteArray:
		var cell_index := VoxelData.get_cell_index(cell_pos)
		var offset := VoxelData.get_cell_offset(cell_index)
		var u16 := (chunk as PackedByteArray).decode_u16(offset * CELL_BUFFER_SIZE)
		return Cell.is_cell(u16)
	
	return false

func set_cell(cell_pos: Vector3i, cell: Cell) -> void:
	var chunk_index := VoxelData.get_chunk_index(cell_pos)
	
	if not chunks.has(chunk_index):
		if cell != null:
			_create_chunk(chunk_index)
		else:
			# remove a cell from a missing chunk: nothing to do
			return
	
	var chunk : PackedByteArray = chunks[chunk_index]
	var cell_index := VoxelData.get_cell_index(cell_pos)
	var offset := VoxelData.get_cell_offset(cell_index)
	
	var u16 := Cell.to_u16(cell)
	chunk.encode_u16(offset * CELL_BUFFER_SIZE, u16)
	
	if cell == null and chunk.count(0) == chunk.size():
		# the chunk is now empty
		_remove_chunk(chunk_index)

func fill_cells(imin: Vector3i, imax: Vector3i, cell: Cell) -> void:
	# TODO improve perf: visit chunk by chunk
	for x in range(imin.x, imax.x + 1):
		for y in range(imin.y, imax.y + 1):
			for z in range(imin.z, imax.z + 1):
				set_cell(Vector3i(x, y, z), cell)

func get_neighbors(cell_pos: Vector3i) -> int:
	var n := 0
	for i in range(Side.size()):
		if has_cell(cell_pos + side_dir[i]):
			n |= (1 << i)
	return n

## [imin (inclusive), imax (inclusive)]
func compute_aabb() -> Array[Vector3i]:
	var imin := Vector3i.ZERO
	var imax := Vector3i.ZERO
	var initialized := false
	
	for chunk_index: Vector3i in chunks.keys():
		var chunk : PackedByteArray = chunks[chunk_index]
		
		if initialized and imin.min(chunk_index * CHUNK_SIZE) == imin and imax.max(chunk_index * CHUNK_SIZE - Vector3i.ONE) == imax:
			continue  # chunk is inside imin/imax
		
		var cell_offset := 0
		for z in range(CHUNK_SIZE):
			for y in range(CHUNK_SIZE):
				for x in range(CHUNK_SIZE):
					var has_content := (chunk.decode_u16(cell_offset * CELL_BUFFER_SIZE) & 1) != 0
					if has_content:
						var cell_pos := Vector3i(x, y, z) + chunk_index * CHUNK_SIZE
						if not initialized:
							imin = cell_pos
							imax = cell_pos
							initialized = true
						else:
							imin = imin.min(cell_pos)
							imax = imin.max(cell_pos)
					cell_offset += 1
	
	return [imin, imax]

func _create_chunk(chunk_index: Vector3i) -> void:
	var c := PackedByteArray()
	c.resize(CHUNK_BUFFER_SIZE)
	chunks[chunk_index] = c
	
	if chunks.size() == 1:
		_update_chunk_aabb()
	elif chunk_index.clamp(chunk_aabb_min, chunk_aabb_max) != chunk_index: 
		_extend_chunk_aabb(chunk_index)

func _remove_chunk(chunk_index: Vector3i) -> void:
	chunks.erase(chunk_index)
	
	if (
		# we know: chunk_aabb_min <= chunk_index <= chunk_aabb_max - 1
		# chunk_aabb_min == chunk_index or chunk_index == chunk_aabb_max
		chunk_aabb_min.x == chunk_index.x or chunk_index.x == chunk_aabb_max.x or
		chunk_aabb_min.y == chunk_index.y or chunk_index.y == chunk_aabb_max.y or
		chunk_aabb_min.z == chunk_index.z or chunk_index.z == chunk_aabb_max.z
	):
		_update_chunk_aabb()

func _extend_chunk_aabb(chunk_index: Vector3i) -> void:
	chunk_aabb_min = chunk_aabb_min.min(chunk_index)
	chunk_aabb_max = chunk_aabb_max.max(chunk_index)

func _update_chunk_aabb() -> void:
	var imin := Vector3i.ZERO
	var imax := Vector3i.ZERO
	var initialized := false
	
	for chunk_index: Vector3i in chunks:
		if not initialized:
			imin = chunk_index
			imax = chunk_index
			initialized = true
		else:
			imin = imin.min(chunk_index)
			imax = imax.max(chunk_index)
	
	chunk_aabb_min = imin
	chunk_aabb_max = imax
