tool
extends TextureArray
class_name MultiTexture

export(Array, Texture) var array
var _depth: int

func _init(depth:int=16):
	_depth = depth
	array = []

func assign(idx: int, tex: Texture):
	if idx < min(len(array), get_depth()):
		array[idx] = tex
		_assign(idx, tex)
		return true
	return false

func _assign(idx: int, tex: Texture):
	var img = null
	if tex != null:
		img = tex.get_data()
		if img and img.get_format() != get_format():
			push_error("Error: MultiTexture: Format mismatch %s -> %s, all your textures must be the same format" % [img.get_format(), get_format()])
			return ERR_INVALID_DATA
	set_layer_data(img, idx)
	return OK

func append(tex: Texture):
	if get_depth() == 0:
		# BUG: Calling create internally causes blank textures, an initial create
		# externally is needed, even if it is just replaced here, see CartoTerrainLayers
		create(tex.get_width(), tex.get_height(), _depth, tex.get_data().get_format(), Texture.FLAGS_DEFAULT)
	if len(array) < get_depth():
		var err = _assign(len(array), tex)
		if err == OK:
			array.append(tex)
			return true
	return false

func insert(idx: int, tex: Texture):
	if len(array) < get_depth():
		array.insert(idx, tex)
		_rebuild(idx)
		return true
	return false

func remove(idx: int):
	if idx < min(len(array), get_depth()):
		array.remove(idx)
		_rebuild(idx)
		return true
	return false

func _rebuild(from:int=0):
	var arr_len = len(array)
	for idx in range(from, get_depth()):
		var tex = array[idx] if idx < arr_len else null
		_assign(idx, tex)
