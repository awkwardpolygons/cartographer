tool
extends Resource
class_name CartoTerrainLayers

export(String) var directory: String
export(int) var resolution: int = 1024
export(TextureArray) var textures setget _set_textures
export(Texture) var masks: Texture
export(Vector2) var uv1_scale = Vector2(1.0, 1.0)
export(int) var selected: int = 0
export(int) var use_triplanar: int = 0
const textures_filename = "terrain_textures.mtex"
const masks_filename = "terrain_masks.tres"
const MAX_LAYERS = 16

signal textures_changed

func _set_textures(ta):
	textures = ta

func set_triplanar(idx: int, on: bool):
	var flag: int = pow(2, idx)
	if on:
		use_triplanar |= flag
	else:
		use_triplanar &= ~flag

func get_triplanar(idx: int) -> bool:
	var flag: int = pow(2, idx)
	return (use_triplanar & flag) > 0

#func _init(dir: String):
#	directory = dir
#	_init_textures()
#	_init_masks()

#func _init_textures():
#	var path = directory.plus_file(textures_filename)
#	if ResourceLoader.exists(path):
#		textures = ResourceLoader.load(path)
#		print("CartoTerrainLayers._init_textures: load ", textures, ", ", textures.array)
#	else:
#		textures = MultiTexture.new(MAX_LAYERS)
#		# BUG: Create the MultiTexture here with depth=0 even though we re-create
#		# it (internally) when we add the first texture, because creating it
#		# automatically, when adding, causes nothing to render, dunno why.
#		textures.create(resolution, resolution, 0, Image.FORMAT_RGBA8, Texture.FLAGS_DEFAULT)
#		print("CartoTerrainLayers._init_textures: create ", textures, ", ", len(textures.array))
#	textures.take_over_path(path)
#	print("CartoTerrainLayers._init_textures: ", textures, ", ", len(textures.array))
#
#func _init_masks():
#	var path = directory.plus_file(masks_filename)
#	if ResourceLoader.exists(path):
#		masks = ResourceLoader.load(path)
#	else:
#		masks = ImageTexture.new()
#		masks.create(resolution * 2, resolution * 2, Image.FORMAT_RGBA8)
#	masks.take_over_path(path)
