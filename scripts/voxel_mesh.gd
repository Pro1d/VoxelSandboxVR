class_name VoxelMesh
extends Node3D

var voxel_data := VoxelData.new()

# Tools:
#   draw point, line, box
#   paint point, line box
#   paint fill similar
#   clear p,l,b
#   select plb
#   translate selection
#   rotate selection (90deg step)

var _chunk_nodes := {} # Dict[chunk_hash, ChunkNode]

@onready var default_scale := scale

func reset_data(vd: VoxelData) -> void:
	assert(vd != null)
	voxel_data = vd # TODO notify data changed (if vd != voxel_data)
	
	# Clear all
	for chunk: VoxelChunkMesh in _chunk_nodes.values():
		chunk.queue_free()
		remove_child(chunk)
	_chunk_nodes.clear()
	
	if not voxel_data.is_empty():
		var p := Perf.new()
		_initial_update()
		p.print_delta("init")

func global_to_voxel(pos: Vector3) -> Vector3i:
	return Vector3i(to_local(pos).round())

## build the full voxel, assume the mesh is currently empty
func _initial_update() -> void:
	for chunk_index: Vector3i in voxel_data.chunks:
		var chunk_node := _create_chunk_node(chunk_index)
		for it in voxel_data.make_chunk_iterator(chunk_index, true):
			if it.cell != null:
				chunk_node.initial_update_cell(it.cell_pos, voxel_data.get_neighbors(it.cell_pos), it.cell)

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

func update_material(imin: Vector3i, imax: Vector3i) -> void:
	for x in range(imin.x, imax.x + 1):
		for y in range(imin.y, imax.y + 1):
			for z in range(imin.z, imax.z + 1):
				var cell_pos := Vector3i(x, y, z)
				var cell := voxel_data.get_cell(cell_pos)
				if cell != null:
					var chunk_index := voxel_data.get_chunk_index(cell_pos)
					var chunk_node := _chunk_nodes.get(chunk_index) as VoxelChunkMesh
					if chunk_node != null:
						chunk_node.update_cell_material(cell_pos, cell)

func update_material_single(cell_pos: Vector3i) -> void:
	var cell := voxel_data.get_cell(cell_pos)
	if cell != null:
		var chunk_index := voxel_data.get_chunk_index(cell_pos)
		var chunk_node := _chunk_nodes.get(chunk_index) as VoxelChunkMesh
		if chunk_node != null:
			chunk_node.update_cell_material(cell_pos, cell)

func update_fill_box(imin: Vector3i, imax: Vector3i, cell: VoxelData.Cell) -> void:
	# padded_imin/padded_imax represent the AABB (inclusive) we need to update
	var padded_imin := imin - Vector3i.ONE
	var padded_imax := imax + Vector3i.ONE
	var cmin := voxel_data.get_chunk_index(padded_imin)
	var cmax := voxel_data.get_chunk_index(padded_imax)
	var cell_cache := VoxelData.Cell.new()
	
	for cx in range(cmin.x, cmax.x + 1):
		for cy in range(cmin.y, cmax.y + 1):
			for cz in range(cmin.z, cmax.z + 1):
				var chunk_index := Vector3i(cx, cy, cz)
				var chunk_pos := chunk_index * voxel_data.chunk_size
				var begin := padded_imin.max(chunk_pos)
				var end := (padded_imax + Vector3i.ONE).min(chunk_pos + Vector3i.ONE * voxel_data.chunk_size)
				if not _chunk_nodes.has(chunk_index):
					_create_chunk_node(chunk_index)
				var chunk_node : VoxelChunkMesh = _chunk_nodes[chunk_index]
				
				for x in range(begin.x, end.x):
					for y in range(begin.y, end.y):
						for z in range(begin.z, end.z):
							var cell_pos := Vector3i(x, y, z)
							var side_min := (cell_pos - imin)
							var side_max := (cell_pos - imax)
							var dmin := side_min[side_min.min_axis_index()]
							var dmax := side_max[side_max.max_axis_index()]
							var dside := mini(dmin, -dmax)
							if dside < 0:
								# outside, neighbors may have changed 
								if cell != null:
									chunk_node.update_cell_mesh(
										cell_pos,
										voxel_data.get_neighbors(cell_pos))
								else:
									# when erasing, outside, the cell mesh may no exist yet (if it had all neighbors) -> need full update
									cell_cache = voxel_data.get_cell(cell_pos, cell_cache)
									if cell_cache != null:
										chunk_node.update_cell(
											cell_pos,
											voxel_data.get_neighbors(cell_pos),
											cell_cache
										)
							elif dside > 0 or (cell == null):
								# inside, nothing to display
								# case of clear: on the border, nothing to display
								chunk_node.clear_cell(cell_pos)
							else:
								# on the border, neighbors and mat may have changed
								chunk_node.update_cell(
									cell_pos,
									voxel_data.get_neighbors(cell_pos),
									cell
								)
				
				if chunk_node.is_empty():
					_chunk_nodes.erase(chunk_index)
					chunk_node.queue_free()

func _update_cell(cell_pos: Vector3i, neighbors: int) -> void:
	var chunk_index := voxel_data.get_chunk_index(cell_pos)
	var chunk_node := _chunk_nodes.get(chunk_index) as VoxelChunkMesh
	if chunk_node == null:
		chunk_node = _create_chunk_node(chunk_index)
	chunk_node.update_cell(cell_pos, neighbors, voxel_data.get_cell(cell_pos))

func _clear_cell(cell_pos: Vector3i) -> void:
	var chunk_index := voxel_data.get_chunk_index(cell_pos)
	var chunk_node := _chunk_nodes.get(chunk_index) as VoxelChunkMesh
	if chunk_node != null:
		chunk_node.clear_cell(cell_pos)
		if chunk_node.is_empty():
			_chunk_nodes.erase(chunk_index)
			chunk_node.queue_free()

func _create_chunk_node(chunk_index: Vector3i) -> VoxelChunkMesh:
	var chunk_node := VoxelChunkMesh.new() #VoxelChunkScene.instantiate() as VoxelChunkMesh
	chunk_node.position = chunk_index * voxel_data.chunk_size
	_chunk_nodes[chunk_index] = chunk_node
	add_child(chunk_node)
	return chunk_node
