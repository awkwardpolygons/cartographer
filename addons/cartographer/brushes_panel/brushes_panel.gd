tool
extends Control

func _ready():
	pass

func _on_add_brush_mask_pressed():
	var bml = $VBoxContainer/BrushMasks/ScrollContainer/BrushMaskList
	$AddMaskFileDialog.popup_centered_ratio(0.67)

func _on_rem_brush_mask_pressed():
	var bml = $VBoxContainer/BrushMasks/ScrollContainer/BrushMaskList
	for item in bml.get_selected_items():
		bml.remove_item(item)

func _on_add_mask_file_dialog_files_selected(paths):
	for path in paths:
		add_brush_from_path(path)

func add_brush_from_path(path: String):
	var bml = $VBoxContainer/BrushMasks/ScrollContainer/BrushMaskList
	bml.add_item(path.replace("res://", "").split("/")[-1], load(path), true)

func rem_brush():
	pass
