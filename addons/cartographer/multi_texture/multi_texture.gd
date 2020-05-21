tool
extends TextureArray
class_name MultiTexture

export(Array, Texture) var array

func _init():
	array = []

func assign(idx: int, tex: Texture):
	if idx < get_depth():
		array[idx] = tex
		_assign(idx, tex)
		return true
	return false

func _assign(idx: int, tex: Texture):
	var img = null
	if tex != null:
		img = tex.get_data()
		if img.get_format() != get_format():
			img.convert(get_format())
	set_layer_data(img, idx)

func append(tex: Texture):
	if len(array) < get_depth():
		array.append(tex)
		_assign(len(array) - 1, tex)
		return true
	return false

func insert(idx: int, tex: Texture):
	if len(array) < get_depth():
		array.insert(idx, tex)
		_rebuild(idx)
		return true
	return false

func remove(idx: int):
	if idx < get_depth():
		array.remove(idx)
		_rebuild(idx)
		return true
	return false

func _rebuild(from:int=0):
	for idx in range(from, min(len(array), get_depth())):
		_assign(idx, array[idx])
