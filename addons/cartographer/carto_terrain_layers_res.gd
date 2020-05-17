tool
extends Resource
class_name CartoTerrainLayers

export(String) var directory: String
export(int) var resolution: int = 1024
export(TextureArray) var textures
export(Texture) var masks: Texture
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

#func _set_texture_paths(arr: Array):
#	texture_paths = arr
#	set_texture(load(arr[-1]), 0)
##	for i in max_layers:
##		if len(arr) > i:
##			var path = arr[i]
##			if not ResourceLoader.exists(path):
##				push_error("CartoTerrainLayers._set_texture_paths: Error could not add %s" % path)
##				return
##			set_texture(load(path), i)

#func set_texture(tex, idx):
#	var img = tex.get_data()
#	img.convert(Image.FORMAT_RGBA8)
#	textures.set_layer_data(img, idx)
#	print("set_texture: ", textures)
##	save()
#
#func save():
#	var path = directory.plus_file(masks_filename)
#	var err = ResourceSaver.save(path, masks)
#	if err:
#		push_error("CartoTerrainLayers: Error saving %s to %s" % [masks, path])
#		return
##	path = directory.plus_file(textures_filename)
##	self.save_texarr(path, textures)
#	path = directory.plus_file("terrain_textures.tres")
#	ResourceSaver.save(path, textures)
#
#static func save_texarr(path, arr, compression=2):
#	var file = File.new()
#	if file.open(path, File.WRITE) != 0:
#		push_error("CartoTerrainLayers: Error opening %s file" % path)
#		return
#
#	file.store_8(ord('G'))
#	file.store_8(ord('D'))
#	file.store_8(ord('A')) # Godot ArrayTexture
#	file.store_8(ord('T')) # Godot streamable texture
#
#	file.store_32(arr.get_width())
#	file.store_32(arr.get_height())
#	file.store_32(arr.get_depth())
#	file.store_32(arr.flags)
#	file.store_32(arr.get_format())
#	file.store_32(compression) # Compression: 0 - lossless (PNG), 1 - vram, 2 - uncompressed
#
#	for i in arr.get_depth():
#		var img = arr.get_layer_data(i)
#		print("save_texarr: ", img)
#		img.clear_mipmaps()
#		file.store_buffer(img.get_data())
#
#	file.close()
