class_name VoxelChunk
extends Node3D

var _cell_nodes := {}  # Dict[Vector3i, Node3D]

func is_empty() -> bool:
	return _cell_nodes.is_empty()

func clear_cell(cell_pos: Vector3i) -> void:
	var cell_node := _cell_nodes.get(cell_pos) as Node3D
	if cell_node != null:
		cell_node.queue_free()
		_cell_nodes.erase(cell_pos)

func update_cell(cell_pos: Vector3i, neighbors: int, cell: VoxelData.Cell) -> void:
	var cell_mesh := _cell_nodes.get(cell_pos) as VoxelCellMesh
	if cell_mesh == null:
		cell_mesh = VoxelCellMesh.create(cell, neighbors)
		add_child(cell_mesh)
		cell_mesh.position = Vector3(cell_pos) - position
		_cell_nodes[cell_pos] = cell_mesh
	else:
		cell_mesh.update_mesh(neighbors)
		cell_mesh.update_material(cell)
