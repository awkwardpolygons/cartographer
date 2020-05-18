tool
extends Control

var terrain_layers: CartoTerrainLayers

onready var AddLayerFileDialog = find_node("AddLayerFileDialog")
onready var Layers = find_node("Layers")

func _ready():
	Layers.clear()
	print("Editor._ready:", terrain_layers, len(terrain_layers.textures.array))
	for tex in terrain_layers.textures.array:
		if tex != null:
			add_layer(tex.resource_path)
		else:
			add_layer(null)
	Layers.select(terrain_layers.selected)

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
	if tex != null:
		Layers.add_item(tex.resource_path.replace("res://", "").split("/")[-1], tex, true)
	else:
		Layers.add_item("none", load("res://addons/cartographer/icon_checkerboard.svg"), true)

func _on_rem_layer():
	while Layers.is_anything_selected():
		var idx = Layers.get_selected_items()[0]
		if terrain_layers.textures.remove(idx):
			Layers.unselect(idx)
			Layers.set_item_text(idx, "none")
			Layers.set_item_icon(idx, load("res://addons/cartographer/icon_checkerboard.svg"))

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
	terrain_layers.selected = idx
