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
	for ch in PaintBrush.MaskChannel:
		
		ChannelPicker.add_item(ch, PaintBrush.MaskChannel[ch])
	
	for md in PaintBrush.Mode:
		ModePicker.add_item(md, PaintBrush.Mode[md])

func _on_add_brush_mask_pressed():
	AddMaskFileDialog.popup_centered_ratio(0.67)

func _on_rem_brush_mask_pressed():
	for item in BrushMasks.get_selected_items():
		BrushMasks.remove_item(item)

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
	BrushMasks.add_item(path.replace("res://", "").split("/")[-1], load(path), true)

func rem_brush():
	pass
