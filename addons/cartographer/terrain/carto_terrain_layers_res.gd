tool
extends Resource
class_name CartoTerrainLayers

export(TextureArray) var textures setget _set_textures
export(ImageTexture) var masks: ImageTexture
export(Vector2) var uv1_scale: Vector2 = Vector2(1, 1)
export(int) var selected: int = 0
export(int) var use_triplanar: int = 0
const MAX_LAYERS = 16

func _set_textures(ta):
	textures = ta
	if masks == null and ta != null:
		create_masks()

func calc_triplanar(idx: int, on: bool):
	var flag: int = pow(2, idx)
	if on:
		return use_triplanar | flag
	else:
		return use_triplanar & ~flag

func set_triplanar(idx: int, on: bool):
	var flag: int = pow(2, idx)
	if on:
		use_triplanar |= flag
	else:
		use_triplanar &= ~flag

func get_triplanar(idx: int) -> bool:
	var flag: int = pow(2, idx)
	return (use_triplanar & flag) > 0

func create_masks():
	masks = ImageTexture.new()
	masks.create(2048, 2048, Image.FORMAT_RGBA8)
