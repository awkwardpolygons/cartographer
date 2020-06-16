tool
extends HeightMapShape
class_name CartoHeightMapShape

export(NodePath) var terrain: NodePath setget _set_terrain

func _set_terrain(t):
	terrain = t
