tool
extends Resource
class_name CartoTerrainLayers

export(String) var directory: String
export(int) var resolution: int = 1024
export(TextureArray) var textures
export(Texture) var masks: Texture
export(int) var selected: int = 0
const textures_filename = "terrain_textures.mtex"
const masks_filename = "terrain_masks.tres"
const max_layers = 16

func _init(dir: String):
	directory = dir
	_init_textures()
	_init_masks()

func _init_textures():
	var path = directory.plus_file(textures_filename)
	if ResourceLoader.exists(path):
		textures = ResourceLoader.load(path)
		print("CartoTerrainLayers._init_textures: load ", textures, ", ", textures.array)
#		textures.set_script(load("res://addons/cartographer/multi_texture.gd"))
	else:
		textures = MultiTexture.new()
		textures.create(resolution, resolution, max_layers, Image.FORMAT_RGBA8)
		print("CartoTerrainLayers._init_textures: create ", textures, ", ", len(textures.array))
	textures.take_over_path(path)
	print("CartoTerrainLayers._init_textures: ", textures, ", ", len(textures.array))

func _init_masks():
	var path = directory.plus_file(masks_filename)
	if ResourceLoader.exists(path):
		masks = ResourceLoader.load(path)
	else:
		masks = ImageTexture.new()
		masks.create(resolution * 2, resolution * 2, Image.FORMAT_RGBA8)
	masks.take_over_path(path)
