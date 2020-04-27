tool
extends Spatial
class_name CartoBrush, "res://addons/cartographer/layer_icon.svg"

export(Texture) var texture
export(Gradient) var incline_mask

const isCartoBrush: bool = true
var mask: Texture

func _ready():
	pass # Replace with function body.
