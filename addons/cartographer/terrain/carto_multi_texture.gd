tool
extends TextureArray
class_name CartoMultiTexture

var selected: int = -1 setget set_selected

func set_selected(i: int):
	selected = i
	emit_signal("changed")

func get_size():
	return Vector2(get_width(), get_height())

func create_data(width: int, height: int, depth: int, format: int, flags: int = 7):
	return {"width": width, "height": height, "depth": depth, "format": format, "flags": flags, "layers": []}

func set_layer(src, idx: int, chn_src: int = -1, chn_dst: int = -1):
	var dst: Image
	var size = get_size()
	
	if src is Texture:
		src = src.get_data()
	if src.get_size() != size:
		src.resize(get_width(), get_height())
	if src.is_compressed():
		src.decompress()
	if src.get_format() != get_format():
		src.convert(get_format())
	
	if chn_src < 0 or chn_dst < 0:
		dst = src
	else:
		dst = get_layer_data(idx)
		src.lock()
		dst.lock()
		for y in size.y:
			for x in size.x:
				var clr = dst.get_pixel(x, y)
				clr[chn_dst] = src.get_pixel(x, y)[chn_src]
				dst.set_pixel(x, y, clr)
		dst.unlock()
		src.unlock()
	
	dst.generate_mipmaps()
	
	prints("1:", data.layers[idx].data)
	set_layer_data(dst, idx)
#	for i in 4:
#		dst.resize(dst.get_width() / 2, dst.get_height() / 2, Image.INTERPOLATE_BILINEAR)
#		set_data_partial(dst, 0, 0, idx, i)
#	data.layers[idx].data.data = dst.data.data
#	data.layers[idx].data.mipmaps = true
#	data.layers[idx].data = dst.data
#	create(data.width, data.height, data.depth, data.format, flags)
#	ResourceSaver.save("res://alb3.mtex", self)
	prints("2:", data.layers[idx].data.data.size(), dst.data.data.size())
	
#	set_layer_data(dst, idx)
#	data.layers[idx].data.data.mipmaps = true
#	prints("dst: ", dst.data.data.size())
#	prints("bfr:", data.layers[idx].data.data.size())
#	data.layers[idx].data.data = dst.data.data
#	prints("lyr: ", data.layers[idx].data.data.size())
#	create(data.width, data.height, data.depth, data.format, flags)
