class_name VoxelMesh
extends Node3D

#const VoxelChunkScene := preload("res://scenes/voxel_chunk.tscn")

var voxel_data := VoxelData.new()

# Tools:
#   draw point, line, box
#   paint point, line box
#   paint fill similar
#   clear p,l,b
#   select plb
#   translate selection
#   rotate selection
#   

var _chunk_nodes := {} # Dict[chunk_hash, ChunkNode]

func reset_data(vd: VoxelData) -> void:
	assert(vd != null)
	voxel_data = vd # TODO notify data changed (if vd != voxel_data)
	for chunk: VoxelChunk in _chunk_nodes.values():
		chunk.queue_free()
		remove_child(chunk)
	_chunk_nodes.clear()
	if not voxel_data.is_empty():
		update(voxel_data.chunk_aabb_min * voxel_data.chunk_size, (voxel_data.chunk_aabb_max + Vector3i.ONE) * voxel_data.chunk_size)

func global_to_voxel(pos: Vector3) -> Vector3i:
	return Vector3i(to_local(pos).round())

## build the full voxel from an empty empty
#func update_init() -> void:
	#for chunk_index: Vector3i in voxel_data.chunks:
		#var chunk_data := _chunk_nodes

func update(imin: Vector3i, imax: Vector3i) -> void:
	imin -= Vector3i.ONE
	imax += Vector3i.ONE
	for x in range(imin.x, imax.x + 1):
		for y in range(imin.y, imax.y + 1):
			for z in range(imin.z, imax.z + 1):
				var cell_pos := Vector3i(x, y, z)
				if voxel_data.has_cell(cell_pos):
					var neighbors := voxel_data.get_neighbors(cell_pos)
					if neighbors == VoxelData.ALL_NEIGHBORS:
						_clear_cell(cell_pos)
					else:
						_update_cell(cell_pos, neighbors)
				else:
					_clear_cell(cell_pos)

func _update_cell(cell_pos: Vector3i, neighbors: int) -> void:
	var chunk_index := voxel_data.get_chunk_index(cell_pos)
	var chunk_node := _chunk_nodes.get(chunk_index) as VoxelChunk
	if chunk_node == null:
		chunk_node = VoxelChunk.new() #VoxelChunkScene.instantiate() as VoxelChunk
		chunk_node.position = chunk_index * voxel_data.chunk_size
		_chunk_nodes[chunk_index] = chunk_node
		add_child(chunk_node)
	chunk_node.update_cell(cell_pos, neighbors, voxel_data.get_cell(cell_pos))

func _clear_cell(cell_pos: Vector3i) -> void:
	var chunk_index := voxel_data.get_chunk_index(cell_pos)
	var chunk_node := _chunk_nodes.get(chunk_index) as VoxelChunk
	if chunk_node != null:
		chunk_node.clear_cell(cell_pos)
		if chunk_node.is_empty():
			_chunk_nodes.erase(chunk_index)
			chunk_node.queue_free()
