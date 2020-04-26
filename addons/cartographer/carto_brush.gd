tool
extends Spatial
class_name CartoBrush, "res://addons/cartographer/layer_icon.svg"

export(Resource) var brush: Resource
export(Texture) var texture
export(Gradient) var incline_mask

const isCartoBrush: bool = true
var mask: Texture

func _ready():
	brush = PaintBrush.new()
	pass # Replace with function body.
