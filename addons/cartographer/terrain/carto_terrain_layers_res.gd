tool
extends Resource
class_name CartoTerrainLayers

export(TextureArray) var textures
export(Texture) var masks: Texture
export(Vector2) var uv1_scale = Vector2(1.0, 1.0)
export(int) var selected: int = 0
export(int) var use_triplanar: int = 0
const MAX_LAYERS = 16

func set_triplanar(idx: int, on: bool):
	var flag: int = pow(2, idx)
	if on:
		use_triplanar |= flag
	else:
		use_triplanar &= ~flag

func get_triplanar(idx: int) -> bool:
	var flag: int = pow(2, idx)
	return (use_triplanar & flag) > 0
