tool
extends SpatialMaterial
class_name CartoTerrainMaterial, "res://addons/cartographer/terrain_icon.svg"

export(float, 0, 180) var angle_min: float = -1
export(float, 0, 180) var angle_max: float = -1
export(Texture) var flowmap: Texture

func _ready():
	pass # Replace with function body.
