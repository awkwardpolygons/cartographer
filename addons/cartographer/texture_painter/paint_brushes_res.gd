tool
extends Resource
class_name PaintBrushes

export(Dictionary) var data: Dictionary = {}

enum Op {CLEAR, ADD, SET, REM}

signal updated

func clear():
	emit_signal("updated", Op.CLEAR, null, null)
	data.clear()

func is_empty() -> bool:
	return data.empty()

func set(k: String, v: PaintBrush):
	var has = data.has(k)
	data[k] = v
	emit_signal("updated", Op.SET if has else Op.ADD, k, v)

func get(k: String, default=null) -> PaintBrush:
	return data.get(k, default)

func rem(k: String) -> bool:
	var val = data.get(k)
	var ret = data.erase(k)
	if ret:
		emit_signal("updated", Op.REM, k, val)
	return ret

func has(k: String) -> bool:
	return data.has(k)

func has_all(keys: Array) -> bool:
	return data.has_all(keys)

func hash() -> int:
	return data.hash()
