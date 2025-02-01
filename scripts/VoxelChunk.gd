class_name VoxelChunk
extends Resource

## Note: the user of this class (only VoxelData so far) is in charge of
## maintaining cell_count and packed_data synchronized.

@export var packed_data : PackedByteArray
@export var cell_count : int

func is_empty() -> bool:
	return cell_count == 0

static func create(packed_data_size: int) -> VoxelChunk:
	var c := VoxelChunk.new()
	c.packed_data.resize(packed_data_size)
	c.cell_count = 0
	return c
