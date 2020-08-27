tool
extends TextureArray
class_name CartoMultiTexture

func get_size():
	return Vector2(get_width(), get_height())

func set_layer(src, idx: int):
	if src is Texture:
		src = src.get_data()
	if src.get_size() != get_size():
		src.resize(get_width(), get_height())
	src.decompress()
	if src.get_format() != get_format():
#		src.decompress()
		src.convert(get_format())
	set_layer_data(src, idx)
