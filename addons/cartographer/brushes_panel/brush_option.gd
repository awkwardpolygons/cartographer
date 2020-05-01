tool
extends HBoxContainer

export(String) var label: String setget _set_label, _get_label
export(float) var selected: int setget _set_selected, _get_selected
export(bool) var disabled: bool setget _set_disabled, _get_disabled

signal item_selected

func _on_selected(id):
	emit_signal("item_selected", id)

func _ready():
	pass # Replace with function body.

func _set_label(text: String):
	$Label.text = text

func _get_label():
	print($Label)
	return $Label.text

func _set_selected(s: int):
	if has_node("Option"):
		$Option.selected = s

func _get_selected():
	return $Option.selected

func _set_disabled(b: bool):
	$Option.disabled = b

func _get_disabled():
	return $Option.disabled

func add_icon_item(texture: Texture, label: String, id: int = -1):
	$Option.add_icon_item(texture, label, id)

func add_item(label: String, id: int = -1):
	$Option.add_item(label, id)

func add_separator():
	$Option.add_separator()

func clear():
	$Option.clear()

func get_item_icon(idx: int):
	return $Option.get_item_icon(idx)

func get_item_text(idx: int):
	return $Option.get_item_text(idx)

func get_item_metadata(idx: int):
	return $Option.get_item_metadata(idx)

func set_items(items: Dictionary, sel=-1):

	for k in items:
		var v = items[k]
		add_item(k, v)
		if v == sel:
			self.selected = v
