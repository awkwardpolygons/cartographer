tool
extends EditorImportPlugin
class_name CartoTextureArrayBuilder

enum Presets { DEFAULT }
enum Compress { Lossless, VRAM, Uncompressed }
enum Format { FORMAT_L8, FORMAT_LA8, FORMAT_R8, FORMAT_RG8, FORMAT_RGB8, FORMAT_RGBA8 }
const formats = {
	"FORMAT_L8": Image.FORMAT_L8,
	"FORMAT_LA8": Image.FORMAT_LA8,
	"FORMAT_R8": Image.FORMAT_R8,
	"FORMAT_RG8": Image.FORMAT_RG8,
	"FORMAT_RGB8": Image.FORMAT_RGB8,
	"FORMAT_RGBA8": Image.FORMAT_RGBA8,
}

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
					"name": "format",
					"default_value": Format.FORMAT_RGBA8,
					"property_hint": PROPERTY_HINT_ENUM,
					"hint_string": "FORMAT_L8,FORMAT_LA8,FORMAT_R8,FORMAT_RG8,FORMAT_RGB8,FORMAT_RGBA8"
				},
#				{
#					"name": "compress",
#					"default_value": null,
#					"hint_string": "compress/",
#					"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_CATEGORY,
#				},
				{
					"name": "compress",
					"default_value": Compress.Uncompressed,
					"property_hint": PROPERTY_HINT_ENUM,
					"hint_string": "Lossless,VRAM,Uncompressed"
				},
#				{
#					"name": "flags",
#					"default_value": null,
#					"hint_string": "flags/",
#					"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_CATEGORY,
#				},
				{
					"name": "flags",
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
	
	var format = options["format"]
	var compress = options["compress"]
	var flags = options["flags"]
	var images = []
	obj.format = format
	
	prints(options, r_platform_variants, r_gen_files)
	
	images = _parse(obj)
	
	if compress == Compress.VRAM:
		err = _save_tex_vram(images, save_path, flags, r_platform_variants)
	else:
		err = _save_tex(images, "%s.%s" % [save_path, get_save_extension()], compress, -1, flags)
	return err

func _parse(obj):
	assert(obj.size is Array and len(obj.size) == 2, "Invalid size, must be an array of two ints: %s" % [obj.size])
	var size = Vector2(obj.size[0], obj.size[1])
	var format = obj.format
	var images = []
	
	for layer in obj.layers:
		var img: Image
		if layer is String:
			img = _load_image(layer, size)
		if layer is Dictionary:
			img = _get_image_from_channels(layer, size, format)
			prints("chn img:", img)
		images.append(img)
	
	return images

func _get_image_from_channels(channels, size: Vector2, format: int = Image.FORMAT_RGBA8):
	var dst_img = Image.new()
	dst_img.create(size.x, size.y, false, format)
	
	for dst in channels:
		assert(channels[dst] is Array and len(channels[dst]) == 2 and channels[dst][0] is String and channels[dst][1] is String, "Invalid format for channels layer: %s" % [channels[dst]])
		assert(len(dst) == len(channels[dst][1]), "Channel index length mismatch: %s, %s" % [dst, channels[dst]])
		var src_img = _load_image(channels[dst][0], size)
		var src = channels[dst][1]
		src_img.lock()
		dst_img.lock()
		for y in size.y:
			for x in size.x:
				var dst_px = dst_img.get_pixel(x, y)
				var src_px = src_img.get_pixel(x, y)
				for i in len(dst):
					var dst_ch = dst[i]
					var src_ch = src[i]
					dst_px[dst_ch] = src_px[src_ch]
				dst_img.set_pixel(x, y, dst_px)
		dst_img.unlock()
		src_img.unlock()
	
	return dst_img

func _load_image(path: String, size: Vector2, format: int = Image.FORMAT_RGBA8) -> Image:
	var img
	if path.begins_with("#"):
		img = Image.new()
		img.create(size.x, size.y, false, format)
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

func _save_tex_vram(images: Array, path: String, flags: int, r_comp: Array):
	if ProjectSettings.get("rendering/vram_compression/import_bptc"):
		r_comp.append("bptc")
		_save_tex(images, "%s.%s.%s" % [path, "bptc", get_save_extension()], Compress.VRAM, Image.COMPRESS_BPTC, flags)
	if ProjectSettings.get("rendering/vram_compression/import_s3tc"):
		r_comp.append("s3tc")
		_save_tex(images, "%s.%s.%s" % [path, "s3tc", get_save_extension()], Compress.VRAM, Image.COMPRESS_S3TC, flags)
	if ProjectSettings.get("rendering/vram_compression/import_etc2"):
		r_comp.append("etc2")
		_save_tex(images, "%s.%s.%s" % [path, "etc2", get_save_extension()], Compress.VRAM, Image.COMPRESS_ETC2, flags)
	if ProjectSettings.get("rendering/vram_compression/import_etc"):
		r_comp.append("etc")
		_save_tex(images, "%s.%s.%s" % [path, "etc", get_save_extension()], Compress.VRAM, Image.COMPRESS_ETC, flags)
	if ProjectSettings.get("rendering/vram_compression/import_pvrtc"):
		r_comp.append("pvrtc")
		_save_tex(images, "%s.%s.%s" % [path, "pvrtc", get_save_extension()], Compress.VRAM, Image.COMPRESS_PVRTC4, flags)

func _save_tex(images: Array, path: String, compression: int = Compress.Uncompressed, vram_compression: int = Image.COMPRESS_S3TC, flags: int = 7):
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
	if compression != Compress.VRAM:
		file.store_32(images[0].get_format())
		file.store_32(compression) # Compression: 0 - lossless (PNG), 1 - vram, 2 - uncompressed
	
	var dim = max(images[0].get_width(), images[0].get_height())
	var mipmap_count =  log(dim) / log(2) + 1
	
	for i in images.size():
		var img = images[i].duplicate() as Image
		var data: PoolByteArray;
		
		if flags & TextureLayered.FLAG_MIPMAPS:
			img.generate_mipmaps()
		else:
			img.clear_mipmaps()
		
		match compression:
			Compress.Lossless:
				file.store_32(mipmap_count)
				for j in mipmap_count:
					if j > 0:
						img.shrink_x2()
					data = img.save_png_to_buffer()
					file.store_32(data.size() + 4)
					file.store_8(ord('P'))
					file.store_8(ord('N'))
					file.store_8(ord('G'))
					file.store_8(ord(' '))
					file.store_buffer(data)
			Compress.VRAM:
				img.compress(vram_compression, 3, 0.7) # COMPRESS_SOURCE_LAYERED = 3, not bound to GDScript?
				if i == 0:
					file.store_32(img.get_format())
					file.store_32(compression)
				data = img.get_data()
				file.store_buffer(data)
			Compress.Uncompressed:
				data = img.get_data()
				file.store_buffer(data)

	file.close()
	return OK
