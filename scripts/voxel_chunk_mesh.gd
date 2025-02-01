class_name VoxelChunkMesh
extends Node3D

var _cell_nodes := {}  # Dict[Vector3i, Node3D]

func is_empty() -> bool:
	return _cell_nodes.is_empty()

func clear_cell(cell_pos: Vector3i) -> void:
	var cell_node := _cell_nodes.get(cell_pos) as VoxelCellMesh
	if cell_node != null:
		remove_child(cell_node)
		VoxelCellMesh.keep_for_reuse(cell_node)
		_cell_nodes.erase(cell_pos)

func update_cell(cell_pos: Vector3i, neighbors: int, cell: VoxelData.Cell) -> void:
	var cell_mesh := _cell_nodes.get(cell_pos) as VoxelCellMesh
	if cell_mesh == null:
		initial_update_cell(cell_pos, neighbors, cell)
	else:
		cell_mesh.update_mesh(neighbors)
		cell_mesh.update_material(cell)

func update_cell_material(cell_pos: Vector3i, cell: VoxelData.Cell) -> void:
	var cell_mesh := _cell_nodes.get(cell_pos) as VoxelCellMesh
	if cell_mesh != null:
		cell_mesh.update_material(cell)

## Does not work if a cell that had all neighbors (before update) actually does not exist and therefore cannot be updated
func update_cell_mesh(cell_pos: Vector3i, neighbors: int) -> void:
	var cell_mesh := _cell_nodes.get(cell_pos) as VoxelCellMesh
	if cell_mesh != null:
		cell_mesh.update_mesh(neighbors)

## Assume no cell
func initial_update_cell(cell_pos: Vector3i, neighbors: int, cell: VoxelData.Cell) -> void:
	var cell_mesh := VoxelCellMesh.create(cell, neighbors)
	add_child(cell_mesh)
	cell_mesh.position = Vector3(cell_pos) - position
	_cell_nodes[cell_pos] = cell_mesh
