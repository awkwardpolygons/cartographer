tool
extends Control

var terrain_layers: CartoTerrainLayers
var icon_checkerboard = preload("res://addons/cartographer/icons/icon_checkerboard.svg")
var undo_redo: UndoRedo

onready var AddLayerFileDialog = find_node("AddLayerFileDialog")
onready var Layers = find_node("Layers")

func _ready():
	undo_redo = Cartographer.undo_redo
	Layers.clear()
	for tex in terrain_layers.textures.array:
		if tex != null:
			Layers.add_item(tex.resource_path.replace("res://", "").split("/")[-1], tex, true)
		else:
			Layers.add_item("none", icon_checkerboard, true)
	Layers.select(terrain_layers.selected)

func _do(name: String, do_method: String, do_args: Array, undo_method: String, undo_args: Array):
	prints(do_method, do_args, undo_method, undo_args)
	undo_redo.create_action(name)
	undo_redo.add_do_method(self, "callv", do_method, do_args)
	undo_redo.add_undo_method(self, "callv", undo_method, undo_args)
	undo_redo.commit_action()

func _exit_tree():
	terrain_layers = null
	Layers.clear()

func _on_add_layer():
	AddLayerFileDialog.mode = FileDialog.MODE_OPEN_FILES
	AddLayerFileDialog.popup_centered_ratio(0.67)

func _on_add_layer_files(paths):
	for path in paths:
		var tex = load(path)
		if terrain_layers.textures.append(tex):
			add_layer(tex)

func add_layer(tex: Texture):
	if terrain_layers.textures.append(tex):
		Layers.add_item(tex.resource_path.replace("res://", "").split("/")[-1], tex, true)

func _on_rem_layer():
	while Layers.is_anything_selected():
		var idx = Layers.get_selected_items()[0]
		rem_layer(idx)

func rem_layer(idx: int):
	if terrain_layers.textures.remove(idx):
		Layers.unselect(idx)
		Layers.set_item_text(idx, "none")
		Layers.set_item_icon(idx, icon_checkerboard)

func _on_activate_layer(index):
	AddLayerFileDialog.mode = FileDialog.MODE_OPEN_FILE
	AddLayerFileDialog.popup_centered_ratio(0.67)

func _on_set_layer_file(path):
	var tex = load(path)
	set_layer(Layers.get_selected_items()[0], tex)

func set_layer(idx: int, tex: Texture):
	if terrain_layers.textures.assign(idx, tex):
		Layers.set_item_text(idx, tex.resource_path.replace("res://", "").split("/")[-1])
		Layers.set_item_icon(idx, tex)

func _on_select_layer(idx):
	prints("_on_select_layer:", idx)
	set_selected(idx)

func set_selected(idx: int):
	terrain_layers.selected = idx
	Layers.select(idx)
