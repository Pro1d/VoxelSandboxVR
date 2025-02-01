class_name VoxelCellMesh
extends Node3D

static func _make_face(orientation: PlaneMesh.Orientation, flip_face: bool, center_offset: Vector3) -> PlaneMesh:
	var plane := PlaneMesh.new()
	plane.orientation = orientation
	plane.center_offset = center_offset
	plane.flip_faces = flip_face
	plane.size = Vector2.ONE
	return plane

static var _side_faces: Array[PlaneMesh] = [
	VoxelCellMesh._make_face(PlaneMesh.FACE_X, false, Vector3(.5, 0, 0)),
	VoxelCellMesh._make_face(PlaneMesh.FACE_X, true, Vector3(-.5, 0, 0)),
	VoxelCellMesh._make_face(PlaneMesh.FACE_Y, false, Vector3(0, .5, 0)),
	VoxelCellMesh._make_face(PlaneMesh.FACE_Y, true, Vector3(0, -.5, 0)),
	VoxelCellMesh._make_face(PlaneMesh.FACE_Z, false, Vector3(0, 0, .5)),
	VoxelCellMesh._make_face(PlaneMesh.FACE_Z, true, Vector3(0, 0, -.5)),
]

static var _cache : Array[VoxelCellMesh]

var _mat : StandardMaterial3D

static func create(cell: VoxelData.Cell, neighbors: int) -> VoxelCellMesh:
	var cell_mesh := _try_reuse(cell, neighbors)
	if cell_mesh != null:
		return cell_mesh
	
	cell_mesh = VoxelCellMesh.new()
	
	# material
	cell_mesh._mat = StandardMaterial3D.new()
	cell_mesh._mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
	cell_mesh._mat.albedo_color = cell.color
	
	# faces
	for i in range(VoxelData.Side.size()):
		var mi := MeshInstance3D.new()
		mi.mesh = _side_faces[i]
		mi.visible = ((neighbors >> i) & 1) == 0
		mi.layers = 0b11
		mi.set_surface_override_material(0, cell_mesh._mat)
		cell_mesh.add_child(mi)

	return cell_mesh

static func _try_reuse(cell: VoxelData.Cell, neighbors: int) -> VoxelCellMesh:
	if _cache.is_empty():
		return null
	var cell_mesh := _cache.pop_back() as VoxelCellMesh
	cell_mesh.update_material(cell)
	cell_mesh.update_mesh(neighbors)
	return cell_mesh

static func keep_for_reuse(cell_mesh: VoxelCellMesh) -> void:
	_cache.append(cell_mesh)

func update_material(cell: VoxelData.Cell) -> void:
	_mat.albedo_color = cell.color

func update_mesh(neighbors: int) -> void:
	for i in range(get_child_count()):
		var mi := get_child(i) as MeshInstance3D
		mi.visible = ((neighbors >> i) & 1) == 0
