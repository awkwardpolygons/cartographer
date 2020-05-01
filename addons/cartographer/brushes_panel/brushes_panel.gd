tool
extends Control

var BrushSlider = preload("res://addons/cartographer/brushes_panel/brush_slider.tscn")
var BrushOption = preload("res://addons/cartographer/brushes_panel/brush_option.tscn")
var active_brush: PaintBrush setget _set_active_brush, _get_active_brush

onready var AddMaskFileDialog = find_node("AddMaskFileDialog")
onready var BrushPreview = find_node("BrushPreview")
onready var BrushMasks = find_node("BrushMasks")
onready var Section1 = find_node("Section1")
onready var Section2 = find_node("Section2")
onready var Section3 = find_node("Section3")

func _ready():
	BrushMasks.clear()
	for k in Cartographer.brushes.data:
		var br = Cartographer.brushes.get(k)
		_add_brush_item(k, br.brush_mask)
	
	_bind(PaintBrush.new())

func _bind(brush, disabled=false):
	_bind_clear()
	var prop_list = brush.get_script().get_script_property_list()
	for prop in prop_list:
		match prop.hint:
			PROPERTY_HINT_RESOURCE_TYPE:
				if prop.hint_string == "Texture":
					BrushPreview.texture = brush.get(prop.name)
			PROPERTY_HINT_ENUM:
				var option = BrushOption.instance()
				option.disabled = disabled
				option.label = snake_to_title(prop.name)
				option.clear()
				option.set_items(get_hint_enum(prop.hint_string), brush.get(prop.name))
				Section1.add_child(option)
				option.connect("item_selected", self, "_on_prop_changed", [prop.name])
			PROPERTY_HINT_RANGE:
				var slider = BrushSlider.instance()
				slider.disabled = disabled
				var rng = get_hint_range(prop.hint_string)
				var name = snake_to_title(prop.name)
				slider.label = name
				slider.set_range(rng, brush.get(prop.name))
				Section2.add_child(slider)
				slider.connect("value_changed", self, "_on_prop_changed", [prop.name])

# TODO: Add a node cache instead of creating and destroying everytime.
func _bind_clear():
	for child in Section1.get_children():
		Section1.remove_child(child)
		child.queue_free()
	for child in Section2.get_children():
		Section2.remove_child(child)
		child.queue_free()

func _on_prop_changed(value, prop_name):
	active_brush.set(prop_name, value)

func get_hint_range(text: String):
	return text.split(",")

func get_hint_enum(text: String):
	var data = {}
	for kv in text.split(","):
		kv = kv.split(":")
		data[kv[0]] = int(kv[1])
	return data

func snake_to_title(text: String):
	var arr = text.split("_")
	for i in range(len(arr)):
		arr[i] = arr[i].capitalize()
	return arr.join(" ")

func _set_active_brush(br: PaintBrush):
	active_brush = br
	_bind(br)

func _get_active_brush():
	return active_brush

func _on_add_brush_mask_pressed():
	AddMaskFileDialog.popup_centered_ratio(0.67)

func _on_rem_brush_mask_pressed():
	for idx in BrushMasks.get_selected_items():
		rem_brush_by_idx(idx)

func _on_add_mask_file_dialog_files_selected(paths):
	for path in paths:
		add_brush_from_path(path)

func _on_mask_selected(index):
	self.active_brush = Cartographer.brushes.get(BrushMasks.get_item_metadata(index))

func add_brush_from_path(path: String):
	var brush = Cartographer.brushes.get(path)
	if not brush:
		brush = PaintBrush.new(load(path))
		Cartographer.brushes.set(path, brush)
		_add_brush_item(path, brush.brush_mask)

func _add_brush_item(path: String, tex: Texture):
	BrushMasks.add_item(path.replace("res://", "").split("/")[-1], tex, true)
	var idx = BrushMasks.get_item_count() - 1
	BrushMasks.set_item_metadata(idx, path)

func rem_brush_by_idx(idx: int):
	var path = BrushMasks.get_item_metadata(idx)
	BrushMasks.remove_item(idx)
	Cartographer.brushes.rem(path)
