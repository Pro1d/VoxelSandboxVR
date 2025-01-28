class_name VoxelChunk
extends Node3D

static func _make_face(orientation: PlaneMesh.Orientation, flip_face: bool, center_offset: Vector3) -> PlaneMesh:
	var plane := PlaneMesh.new()
	plane.orientation = orientation
	plane.center_offset = center_offset
	plane.flip_faces = flip_face
	plane.size = Vector2.ONE
	prints("create plane", orientation, flip_face, center_offset)
	return plane

static var _side_faces: Array[PlaneMesh] = [
	VoxelChunk._make_face(PlaneMesh.FACE_X, false, Vector3(.5, 0, 0)),
	VoxelChunk._make_face(PlaneMesh.FACE_X, true, Vector3(-.5, 0, 0)),
	VoxelChunk._make_face(PlaneMesh.FACE_Y, false, Vector3(0, .5, 0)),
	VoxelChunk._make_face(PlaneMesh.FACE_Y, true, Vector3(0, -.5, 0)),
	VoxelChunk._make_face(PlaneMesh.FACE_Z, false, Vector3(0, 0, .5)),
	VoxelChunk._make_face(PlaneMesh.FACE_Z, true, Vector3(0, 0, -.5)),
]

var _cell_nodes := {}  # Dict[Vector3i, Node3D]

func is_empty() -> bool:
	return _cell_nodes.is_empty()

func clear_cell(cell_pos: Vector3i) -> void:
	var cell_node := _cell_nodes.get(cell_pos) as Node3D
	if cell_node != null:
		cell_node.queue_free()
		_cell_nodes.erase(cell_pos)

func update_cell(cell_pos: Vector3i, neighbors: int, cell: VoxelData.Cell) -> void:
	var cell_node := _cell_nodes.get(cell_pos) as Node3D
	if cell_node == null:
		cell_node = Node3D.new()
		for i in range(VoxelData.Side.size()):
			var mi := MeshInstance3D.new()
			mi.mesh = _side_faces[i]
			mi.visible = ((neighbors >> i) & 1) == 0
			var mat := StandardMaterial3D.new()
			mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
			mat.albedo_color = cell.color
			mi.set_surface_override_material(0, mat)
			cell_node.add_child(mi)
		add_child(cell_node)
		cell_node.position = Vector3(cell_pos) - position
		_cell_nodes[cell_pos] = cell_node
	else:
		var i := 1
		for mi: MeshInstance3D in (_cell_nodes[cell_pos] as Node3D).get_children():
			mi.visible = (neighbors & i) == 0
			var mat := mi.get_surface_override_material(0) as StandardMaterial3D
			mat.albedo_color = cell.color
			i <<= 1
