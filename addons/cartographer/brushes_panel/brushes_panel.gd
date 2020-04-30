tool
extends Control

onready var AddMaskFileDialog = find_node("AddMaskFileDialog")
onready var BrushPreview = find_node("BrushPreview")
onready var ChannelPicker = find_node("ChannelPicker")
onready var ModePicker = find_node("ModePicker")
onready var BrushStrength = find_node("BrushStrength")
onready var BrushScale = find_node("BrushScale")
onready var BrushRotation = find_node("BrushRotation")
onready var BrushMasks = find_node("BrushMasks")

func _ready():
	Cartographer.brushes.connect("updated", self, "_brushes_updated")
	for ch in PaintBrush.MaskChannel:
		ChannelPicker.add_item(ch, PaintBrush.MaskChannel[ch])
	
	for md in PaintBrush.Mode:
		ModePicker.add_item(md, PaintBrush.Mode[md])
		
	for k in Cartographer.brushes.data:
		var br = Cartographer.brushes.get(k)
		_add_brush_item(k, br.brush_mask)

func _on_add_brush_mask_pressed():
	AddMaskFileDialog.popup_centered_ratio(0.67)

func _on_rem_brush_mask_pressed():
	for idx in BrushMasks.get_selected_items():
		rem_brush_by_idx(idx)

func _on_add_mask_file_dialog_files_selected(paths):
	for path in paths:
		add_brush_from_path(path)

func _on_mask_selected(index):
	ChannelPicker.disabled = false
	ModePicker.disabled = false
	BrushStrength.disabled = false
	BrushScale.disabled = false
	BrushRotation.disabled = false

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
