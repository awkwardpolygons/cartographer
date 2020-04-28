extends Resource
class_name PaintBrushes

export(Dictionary) var brushes: Dictionary = {}

func set(k: String, v: PaintBrush):
	brushes[k] = v

func get(k: String) -> PaintBrush:
	return brushes[k]

func rem(k: String) -> bool:
	return brushes.erase(k)
