tool
extends TextureArray
class_name MultiTexture

export(Array, Texture) var array

func _init():
	array = []

func assign(idx, tex):
	array[idx] = tex
	_assign(idx, tex)

func _assign(idx, tex):
	var img = tex.get_data()
	if img.get_format() != get_format():
		img.convert(get_format())
	set_layer_data(img, idx)

func append(tex: Texture):
	if len(array) < get_depth():
		array.append(tex)
	else:
		return false
	return true

func remove(idxs):
	var ta = []
	var has = {}
	
	if idxs is Array:
		for i in idxs:
			has[i] = true
	elif idxs is Dictionary:
		has = idxs
	else:
		push_error("Can only accept Array or Dictionary")
	
	for i in len(array):
		if not has.get(i, false):
			ta.append(array[i])
	array = ta
