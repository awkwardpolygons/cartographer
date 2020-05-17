tool
extends Control

var terrain_layers: CartoTerrainLayers

onready var AddLayerFileDialog = find_node("AddLayerFileDialog")
onready var Layers = find_node("Layers")

func _ready():
	Layers.clear()
	print("Editor._ready:", terrain_layers, len(terrain_layers.textures.array))
	for tex in terrain_layers.textures.array:
		add_layer_from_path(tex.resource_path)

func _exit_tree():
	terrain_layers = null

func _on_add_layer():
	AddLayerFileDialog.popup_centered_ratio(0.67)

func _on_add_layer_files(paths):
	for path in paths:
		print(path)
		add_layer_from_path(path)
		var tex = load(path)
		terrain_layers.textures.append(tex)

func add_layer_from_path(path: String):
	var tex = load(path)
	Layers.add_item(path.replace("res://", "").split("/")[-1], tex, true)

func _on_rem_layer():
	while Layers.is_anything_selected():
		Layers.remove_item(Layers.get_selected_items()[0])
