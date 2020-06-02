tool
extends TextureRect
class_name TextureArrayRect

export(TextureArray) var texture_array
export(int, 0, 1000) var layer: int = 0 setget _set_layer

func _set_layer(idx: int):
	if texture_array == null:
		return
	
	layer = min(idx, texture_array.get_depth())
	
	if texture == null || not (texture is ImageTexture):
		texture = ImageTexture.new()
	texture.create_from_image(texture_array.get_layer_data(layer))
