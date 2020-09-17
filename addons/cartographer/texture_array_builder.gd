tool
extends EditorImportPlugin
class_name CartoTextureArrayBuilder

enum Presets { DEFAULT }
enum Compress { Lossless, Lossy, VRAM, Uncompressed }

func get_importer_name():
	return "texture_array_builder"

func get_visible_name():
	return "TextureArrayBuilder"

func get_recognized_extensions():
	return ["tabld"]

func get_save_extension():
	return "texarr"

func get_resource_type():
	return "TextureArray"

func get_preset_count():
	return Presets.size()

func get_preset_name(preset):
	return ""

func get_import_options(preset):
	match preset:
		Presets.DEFAULT:
			return [
				{
					"name": "compress",
					"default_value": null,
					"hint_string": "compress/",
					"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_CATEGORY,
				},
				{
					"name": "compress/mode",
					"default_value": Compress.Uncompressed,
					"property_hint": PROPERTY_HINT_ENUM,
					"hint_string": "Lossless,Lossy,VRAM,Uncompressed"
				},
				{
					"name": "flags",
					"default_value": null,
					"hint_string": "flags/",
					"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_CATEGORY,
				},
				{
					"name": "flags/flags",
					"default_value": 7,
					"property_hint": PROPERTY_HINT_FLAGS,
					"hint_string": "Mipmaps,Repeat,Filter"
				},
			]
		_:
			return []

func get_option_visibility(option, options):
	return true

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = File.new()
	var err = file.open(source_file, File.READ)
	if err != OK:
		file.close()
		return err
	var json = file.get_as_text()
	file.close()
	var parsed = JSON.parse(json)
	if parsed.error != OK:
		return parsed.error
	var obj = parsed.result
	
	var size: Vector2
	if obj.has("size") and obj.size is Array:
		size = Vector2(obj.size[0], obj.size[0])
	else:
		return ERR_INVALID_DATA
	
	prints(options, r_platform_variants, r_gen_files)
	
	var images = []
	for layer in obj.layers:
		var img: Image
		if layer is String:
			img = _load_image(layer, size)
		elif layer is Array and layer.size() > 0:
			img = Image.new()
			img.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			var channels = []
			for chn in layer:
				var src = _load_image(chn[0], size)
				var idx = chn[1]
				channels.append([src, idx])
				src.lock()
			img.lock()
			for y in size.y:
				for x in size.x:
					var clr = Color()
					for i in channels.size():
						var chn = channels[i]
						var src = chn[0]
						var idx = chn[1]
						clr[i] = src.get_pixel(x, y)[idx]
					img.set_pixel(x, y, clr)
			img.unlock()
			for chn in channels:
				var src = chn[0]
				src.unlock()
		images.append(img)
	
	return _save_tex(images, "%s.%s" % [save_path, get_save_extension()])
#	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], obj)

func _load_image(path: String, size: Vector2) -> Image:
	var img
	if path.begins_with("#"):
		img = Image.new()
		img.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		img.fill(Color(path))
	elif path.begins_with("file://"):
		img = Image.new()
		img.load(path.substr(5))
	else:
		img = load(path)
	if img is Texture:
		img = img.get_data()
	img.decompress()
	img.resize(size.x, size.y)
	return img

func _save_tex(images: Array, path: String, compression: int = 2, vram_compression: int = Image.COMPRESS_S3TC, flags: int = 7):
	prints(path, images)
#	return FAILED
	if images.size() == 0:
		return FAILED
	
	var file = File.new()
	var err = file.open(path, File.WRITE)
	if err != 0:
		return err
	
	file.store_8(ord('G'))
	file.store_8(ord('D'))
	file.store_8(ord('A')) # Godot ArrayTexture
	file.store_8(ord('T')) # Godot streamable texture

	file.store_32(images[0].get_width())
	file.store_32(images[0].get_height())
	file.store_32(images.size())
	file.store_32(flags)
	file.store_32(images[0].get_format())
	file.store_32(compression) # Compression: 0 - lossless (PNG), 1 - vram, 2 - uncompressed


	for i in images.size():
		var img = images[i] as Image
		if flags & TextureLayered.FLAG_MIPMAPS:
			img.generate_mipmaps()
		else:
			img.clear_mipmaps()
		file.store_buffer(img.get_data())

	file.close()
	return OK
