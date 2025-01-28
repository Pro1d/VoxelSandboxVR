class_name VoxelMesh
extends Node3D

const VoxelChunkScene := preload("res://scenes/voxel_chunk.tscn")

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

func global_to_voxel(pos: Vector3) -> Vector3i:
	return Vector3i(to_local(pos).round())

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
	var chunk_index := VoxelData.get_chunk_index(cell_pos)
	var chunk_node := _chunk_nodes.get(chunk_index) as VoxelChunk
	if chunk_node == null:
		chunk_node = VoxelChunkScene.instantiate()  as VoxelChunk # VoxelChunk.new()
		chunk_node.position = chunk_index * VoxelData.CHUNK_SIZE
		_chunk_nodes[chunk_index] = chunk_node
		add_child(chunk_node)
	chunk_node.update_cell(cell_pos, neighbors, voxel_data.get_cell(cell_pos))

func _clear_cell(cell_pos: Vector3i) -> void:
	var chunk_index := VoxelData.get_chunk_index(cell_pos)
	var chunk_node := _chunk_nodes.get(chunk_index) as VoxelChunk
	if chunk_node != null:
		chunk_node.clear_cell(cell_pos)
		if chunk_node.is_empty():
			_chunk_nodes.erase(chunk_index)
			chunk_node.queue_free()
