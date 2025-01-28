@tool
extends EditorScript

func _run() -> void:
	var voxel_data := VoxelData.new()
	prints(voxel_data.chunk_aabb_min, voxel_data.chunk_aabb_max, voxel_data.chunks.keys())
	assert(voxel_data.is_empty())
	
	voxel_data._create_chunk(Vector3i(1, 2, 3))
	prints(voxel_data.chunk_aabb_min, voxel_data.chunk_aabb_max, voxel_data.chunks.keys())
	assert(not voxel_data.is_empty())
	assert(voxel_data.chunk_aabb_min == Vector3i(1, 2, 3))
	assert(voxel_data.chunk_aabb_max == Vector3i(1, 2, 3))

	voxel_data._create_chunk(Vector3i(1, 3, 3))
	prints(voxel_data.chunk_aabb_min, voxel_data.chunk_aabb_max, voxel_data.chunks.keys())
	assert(not voxel_data.is_empty())
	assert(voxel_data.chunk_aabb_min == Vector3i(1, 2, 3))
	assert(voxel_data.chunk_aabb_max == Vector3i(1, 3, 3))

	voxel_data._create_chunk(Vector3i(-1, -2, -3))
	prints(voxel_data.chunk_aabb_min, voxel_data.chunk_aabb_max, voxel_data.chunks.keys())
	assert(not voxel_data.is_empty())
	assert(voxel_data.chunk_aabb_min == Vector3i(-1, -2, -3))
	assert(voxel_data.chunk_aabb_max == Vector3i(1, 3, 3))
	
	voxel_data._create_chunk(Vector3i(0, 0, 0))
	prints(voxel_data.chunk_aabb_min, voxel_data.chunk_aabb_max, voxel_data.chunks.keys())
	assert(not voxel_data.is_empty())
	assert(voxel_data.chunk_aabb_min == Vector3i(-1, -2, -3))
	assert(voxel_data.chunk_aabb_max == Vector3i(1, 3, 3))
	
	
	voxel_data._remove_chunk(Vector3i(0, 0, 0))
	prints(voxel_data.chunk_aabb_min, voxel_data.chunk_aabb_max, voxel_data.chunks.keys())
	assert(not voxel_data.is_empty())
	assert(voxel_data.chunk_aabb_min == Vector3i(-1, -2, -3))
	assert(voxel_data.chunk_aabb_max == Vector3i(1, 3, 3))
	
	voxel_data._remove_chunk(Vector3i(1, 2, 3))
	prints(voxel_data.chunk_aabb_min, voxel_data.chunk_aabb_max, voxel_data.chunks.keys())
	assert(not voxel_data.is_empty())
	assert(voxel_data.chunk_aabb_min == Vector3i(-1, -2, -3))
	assert(voxel_data.chunk_aabb_max == Vector3i(1, 3, 3))
	
	voxel_data._remove_chunk(Vector3i(1, 3, 3))
	prints(voxel_data.chunk_aabb_min, voxel_data.chunk_aabb_max, voxel_data.chunks.keys())
	assert(not voxel_data.is_empty())
	assert(voxel_data.chunk_aabb_min == Vector3i(-1, -2, -3))
	assert(voxel_data.chunk_aabb_max == Vector3i(-1, -2, -3))
	
	voxel_data._remove_chunk(Vector3i(-1, -2, -3))
	prints(voxel_data.chunk_aabb_min, voxel_data.chunk_aabb_max, voxel_data.chunks.keys())
	assert(voxel_data.is_empty())
	#assert(voxel_data.chunk_aabb_min == Vector3i(-1, -2, -3))
	#assert(voxel_data.chunk_aabb_max == Vector3i(-1, -2, -3))
