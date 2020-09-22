tool
extends EditorProperty

var hint_text: String
var box: CartoAxisLayout
var grid: GridContainer

func _init():
	size_flags_horizontal = SIZE_FILL
	box = CartoAxisLayout.new()
	grid = GridContainer.new()
	grid.size_flags_horizontal = SIZE_FILL
	grid.columns = 8

func _ready():
	box.add_child(grid)
	add_child(box)
	set_bottom_editor(box)

func update_property():
	var val: int = get_edited_object().get(get_edited_property())
	var items = hint_text.split(",")
	var have = grid.get_child_count()
	var want = len(items)
	
	for i in want:
		if i >= have:
			grid.add_child(CheckBox.new())
		var flg: int = pow(2, i)
		var chk = grid.get_child(i)
		chk.toggle_mode = true
		chk.pressed = val & flg
		chk.set_tooltip(items[i])
		if chk.is_connected("toggled", self, "_on_toggle"):
			chk.disconnect("toggled", self, "_on_toggle")
		chk.connect("toggled", self, "_on_toggle", [i])
	
	for i in have - want:
		var chk = grid.get_child(have - i - 1)
		grid.remove_child(chk)
		chk.queue_free()

func _on_toggle(on, idx):
	var val: int = get_edited_object().get(get_edited_property())
	var flg: int = pow(2, idx)
	val = val | flg if on else val ^ flg
	emit_changed(get_edited_property(), val)
