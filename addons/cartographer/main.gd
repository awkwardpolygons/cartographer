tool
extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var layers = find_node("Layers")
	var root = layers.create_item()
	var item = layers.create_item(root)
	item.set_text(0, "Layer 1")
	
	#find_node("Layers").add_item("Layer 2", null, true)
	print("Cartographer")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
