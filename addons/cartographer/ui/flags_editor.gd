tool
extends EditorProperty

var hint_text: String
var grid: GridContainer

func _init():
	grid = GridContainer.new()
	grid.columns = 8
	add_child(grid)
	set_bottom_editor(grid)

func update_property():
	var val: int = get_edited_object().get(get_edited_property())
	var items = hint_text.split(",")
	var count = len(items)
	
	for ch in grid.get_children():
		grid.remove_child(ch)
		ch.queue_free()
	
	for i in count:
		var flg: int = pow(2, i)
		var chk = CheckBox.new()
		grid.add_child(chk)
		chk.pressed = val & flg
		chk.set_tooltip(items[i])
		chk.connect("toggled", self, "_on_toggle", [i])

func _on_toggle(on, idx):
	var val: int = get_edited_object().get(get_edited_property())
	var flg: int = pow(2, idx)
	val = val | flg if on else val ^ flg
	emit_changed(get_edited_property(), val)
