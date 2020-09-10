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
	set_layer_data(dst, idx)
	emit_signal("changed")
	property_list_changed_notify()

func get_layer(idx: int) -> Image:
	if idx < data.layers.size():
		return data.layers[idx]
	return null
