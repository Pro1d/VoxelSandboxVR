class_name ThumbnailRenderer
extends SubViewport

signal rendered(i: Image)

@onready var _camera := $Camera3D as Camera3D

var image : Image
var rendering := false

func render_voxel(voxel_mesh: VoxelMesh, view_origin: Vector3) -> Image:
	if rendering:
		return
	rendering = true
	
	var voxel_data := voxel_mesh.voxel_data
	
	# Compute bounding sphere
	var corner1 := voxel_mesh.to_global(
		voxel_data.chunk_aabb_min * VoxelData.CHUNK_SIZE
	)
	var corner2 := voxel_mesh.to_global(
		(Vector3(voxel_data.chunk_aabb_max) + Vector3.ONE) * VoxelData.CHUNK_SIZE - Vector3.ONE
	)
	var center := (corner1 + corner2) / 2
	var radius := maxf(center.distance_to(corner2), 0.01)  # ensure not empty bounding sphere
	
	# Compute camera parameters
	if view_origin.distance_to(center) < 0.001: # ensure center != view_origin
		view_origin = center + Vector3.ONE
	var near := _camera.near
	var cam_origin := center + center.direction_to(view_origin) * (radius + near)
	var cam_transform := Transform3D(Basis(), cam_origin).looking_at(center, Vector3.UP)
	_camera.global_transform = cam_transform
	_camera.size = radius * 2
	
	# Trigger render
	render_target_update_mode = UPDATE_ONCE
	await RenderingServer.frame_post_draw
	
	# Get image
	image = get_viewport().get_texture().get_image()
	rendering = false
	rendered.emit(image)
	return image
