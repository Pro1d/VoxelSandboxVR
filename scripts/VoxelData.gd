class_name VoxelData
extends Resource

const CURRENT_VERSION := 0
#const chunk_size := 4 # cell
#const cell_buffer_size := 2 # Bytes
#const chunk_buffer_size := chunk_size * chunk_size * chunk_size * cell_buffer_size
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
	
	func from_u16_cache(u16: int) -> bool:
		return Cell.from_u16(u16, self) != null
		
	static func is_cell(u16: int) -> bool:
		return ((u16 & 0b1111) != 0)
	
	static func from_u16(u16: int, cell_cache: Cell = null) -> Cell:
		if Cell.is_cell(u16):
			if cell_cache == null:
				cell_cache = Cell.new()
			cell_cache.color.r8 = (((u16 >> 4) & 0b1111) * 0b00010001)
			cell_cache.color.g8 = (((u16 >> 8) & 0b1111) * 0b00010001)
			cell_cache.color.b8 = (((u16 >> 12) & 0b1111) * 0b00010001)
			return cell_cache
		else:
			return null
	
	static func to_u16(cell: Cell) -> int:
		var u16 := 0
		if cell != null:
			u16 = 0x0001
			u16 |= (cell.color.r8 & 0b11110000)
			u16 |= (cell.color.g8 & 0b11110000) << 4
			u16 |= (cell.color.b8 & 0b11110000) << 8
		return u16

@export var version := CURRENT_VERSION
@export var chunks : Dictionary  # Dict[Vector3i, VoxelChunk]

@export var chunk_aabb_min : Vector3i
@export var chunk_aabb_max : Vector3i

@export var chunk_size := 4 # cells
@export var cell_buffer_size := 2 # bytes
var chunk_buffer_size: int:
	get():
		return chunk_size * chunk_size * chunk_size * cell_buffer_size

func get_chunk_index(cell_pos: Vector3i) -> Vector3i:
	return (cell_pos - get_cell_index(cell_pos)) / chunk_size

func get_cell_index(cell_pos: Vector3i) -> Vector3i:
	return Vector3i(
		posmod(cell_pos.x, chunk_size),
		posmod(cell_pos.y, chunk_size),
		posmod(cell_pos.z, chunk_size),
	)

func get_cell_offset(cell_index: Vector3i) -> int:
	return cell_index.x + chunk_size * (cell_index.y + chunk_size * cell_index.z)

func is_empty() -> bool:
	return chunks.is_empty()

### SINGLE CELL

func get_cell(cell_pos: Vector3i, cell_cache: Cell = null) -> Cell:
	var chunk_index := get_chunk_index(cell_pos)
	var chunk : VoxelChunk = chunks.get(chunk_index)
	
	var cell : Cell = null
	if chunk != null:
		var cell_index := get_cell_index(cell_pos)
		var offset := get_cell_offset(cell_index)
		var u16 := chunk.packed_data.decode_u16(offset * cell_buffer_size)
		cell = Cell.from_u16(u16, cell_cache)
	
	return cell

func has_cell(cell_pos: Vector3i) -> bool:
	var chunk_index := get_chunk_index(cell_pos)
	var chunk : VoxelChunk = chunks.get(chunk_index)
	
	if chunk != null:
		var cell_index := get_cell_index(cell_pos)
		var offset := get_cell_offset(cell_index)
		var u16 := chunk.packed_data.decode_u16(offset * cell_buffer_size)
		return Cell.is_cell(u16)
	
	return false

func set_cell(cell_pos: Vector3i, cell: Cell) -> void:
	var chunk_index := get_chunk_index(cell_pos)
	var put := (cell != null)  # true=put ; false=erase
	
	if not chunks.has(chunk_index):
		if put:
			_create_chunk(chunk_index)
		else:
			# remove a cell from a missing chunk: nothing to do
			return
	
	var chunk : VoxelChunk = chunks[chunk_index]
	var cell_index := get_cell_index(cell_pos)
	var offset := get_cell_offset(cell_index)
	
	var prev_u16 := chunk.packed_data.decode_u16(offset * cell_buffer_size)
	var was_cell := Cell.is_cell(prev_u16)
	var u16 := Cell.to_u16(cell)
	chunk.packed_data.encode_u16(offset * cell_buffer_size, u16)
	if was_cell != put:
		chunk.cell_count += -1 if was_cell else +1
	
	if not put and chunk.is_empty():
		# the chunk is now empty
		_remove_chunk(chunk_index)

### BOX OF CELLS

func fill_cells(imin: Vector3i, imax: Vector3i, cell: Cell) -> void:
	#for x in range(imin.x, imax.x + 1):
		#for y in range(imin.y, imax.y + 1):
			#for z in range(imin.z, imax.z + 1):
				#set_cell(Vector3i(x, y, z), cell)
	# Improve perf:
	#  - visit chunk by chunk
	#  - cell<->u16 conversion only once
	
	var u16 := Cell.to_u16(cell)
	var cmin := get_chunk_index(imin)
	var cmax := get_chunk_index(imax)
	
	for cx in range(cmin.x, cmax.x + 1):
		for cy in range(cmin.y, cmax.y + 1):
			for cz in range(cmin.z, cmax.z + 1):
				var chunk_index := Vector3i(cx, cy, cz)
				var begin := imin.max(chunk_index * chunk_size) - chunk_index * chunk_size
				var end := (imax + Vector3i.ONE).min((chunk_index + Vector3i.ONE) * chunk_size) - chunk_index * chunk_size
				if not chunks.has(chunk_index):
					_create_chunk(chunk_index)
				var chunk : VoxelChunk = chunks[chunk_index]
				
				for x in range(begin.x, end.x):
					for y in range(begin.y, end.y):
						for z in range(begin.z, end.z):
							var offset := get_cell_offset(Vector3i(x, y, z))
							
							var prev_u16 := chunk.packed_data.decode_u16(offset * cell_buffer_size)
							chunk.packed_data.encode_u16(offset * cell_buffer_size, u16)
							if Cell.is_cell(prev_u16) != (cell != null):
								chunk.cell_count += 1 if (cell != null) else -1

### UTILS

func get_neighbors(cell_pos: Vector3i) -> int:
	var n := 0
	for i in range(Side.size()):
		if has_cell(cell_pos + side_dir[i]):
			n |= (1 << i)
	return n

func make_chunk_iterator(chunk_index: Vector3i, decode: bool) -> ChunkIterator:
	var vc : VoxelChunk = chunks[chunk_index] if decode else null
	return ChunkIterator.new(chunk_index, chunk_size, cell_buffer_size, vc)

## [imin (inclusive), imax (inclusive)]
func compute_aabb() -> Array[Vector3i]:
	var imin := Vector3i.ZERO
	var imax := Vector3i.ZERO
	var initialized := false
	
	for chunk_index: Vector3i in chunks.keys():
		var chunk : VoxelChunk = chunks[chunk_index]
		
		if (
			initialized
			and imin.min(chunk_index * chunk_size) == imin
			and imax.max((chunk_index + Vector3i.ONE) * chunk_size - Vector3i.ONE) == imax
		):
			continue  # chunk is inside imin/imax
		
		var count := 0
		for it in make_chunk_iterator(chunk_index, false):
			var has_content := (chunk.packed_data.decode_u16(it.byte_offset) & 0b1111) != 0
			if has_content:
				if not initialized:
					imin = it.cell_pos
					imax = it.cell_pos
					initialized = true
				else:
					imin = imin.min(it.cell_pos)
					imax = imin.max(it.cell_pos)
				count += 1
				if count >= chunk.cell_count:
					break
	
	return [imin, imax]

func _create_chunk(chunk_index: Vector3i) -> void:
	chunks[chunk_index] = VoxelChunk.create(chunk_buffer_size)
	
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

class ChunkIterator:
	class Value:
		var cell_pos : Vector3i
		var byte_offset : int
		var cell : VoxelData.Cell
	
	var _cbf : int
	var _chunk_begin : Vector3i
	var _chunk_end : Vector3i
	var _value : Value = Value.new()
	var _decode_chunk : VoxelChunk
	var _cache_cell := VoxelData.Cell.new()
	
	func _init(chunk_index: Vector3i, chunk_size: int, cell_buffer_size: int, decode_chunk: VoxelChunk) -> void:
		_cbf = cell_buffer_size
		_chunk_begin = chunk_index * chunk_size
		_chunk_end = _chunk_begin + Vector3i.ONE * chunk_size
		_decode_chunk = decode_chunk

	func _iter_init(_arg: Variant) -> bool:
		_value.cell_pos = _chunk_begin
		_value.byte_offset = 0
		if _decode_chunk != null:
			_value.cell = VoxelData.Cell.from_u16(
				_decode_chunk.packed_data.decode_u16(_value.byte_offset),
				_cache_cell
			)
		return true
	
	func _iter_next(_arg: Variant) -> bool:
		_value.cell_pos.x += 1
		if _value.cell_pos.x >= _chunk_end.x:
			_value.cell_pos.x = _chunk_begin.x
			_value.cell_pos.y += 1
			if _value.cell_pos.y >= _chunk_end.y:
				_value.cell_pos.y = _chunk_begin.y
				_value.cell_pos.z += 1
				if _value.cell_pos.z >= _chunk_end.z:
					return false
		
		_value.byte_offset += _cbf
		if _decode_chunk != null:
			_value.cell = VoxelData.Cell.from_u16(
				_decode_chunk.packed_data.decode_u16(_value.byte_offset),
				_cache_cell
			)
		
		return true
	
	func _iter_get(_arg: Variant) -> Value:
		return _value
