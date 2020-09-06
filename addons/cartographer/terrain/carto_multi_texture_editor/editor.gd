tool
extends EditorProperty

const Layer = preload("res://addons/cartographer/terrain/carto_multi_texture_editor/layer.gd")
var layer_list: CartoAxisLayout
var layer_group: ButtonGroup
var create_button: Button
var create_dialog: WindowDialog

func _init():
	layer_list = CartoAxisLayout.new()
	layer_list.pad_primary_start = 10
	layer_list.pad_primary_end = 10
	layer_list.pad_secondary_start = 10
	layer_list.pad_secondary_end = 10
	layer_list.spacing = 10
	layer_list.anchor_right = ANCHOR_END

	layer_group = ButtonGroup.new()
	
	create_button = Button.new()
	create_button.text = "Create"
	create_button.rect_min_size = Vector2(32, 32)
	create_button.size_flags_horizontal = SIZE_EXPAND_FILL
	create_button.connect("pressed", self, "on_create_pressed")
	
	create_dialog = preload("res://addons/cartographer/terrain/carto_multi_texture_editor/create_dialog.tscn").instance()
	create_dialog.connect("acknowledged", self, "on_create_acknowledged")

func on_create_pressed():
	create_dialog.popup_centered(Vector2(400, 200))

func on_create_acknowledged(ok, vals):
	var mtex = get_edited_object()
	if not ok or not mtex:
		return
	
	var flags = TextureLayered.FLAG_MIPMAPS | TextureLayered.FLAG_REPEAT | TextureLayered.FLAG_FILTER
	prints(flags)
	mtex.create(vals[0], vals[1], vals[2], vals[3], flags)
	var img = Image.new()
	img.create(vals[0], vals[1], false, vals[3])
	
	for i in vals[2]:
		mtex.set_layer_data(img, i)
	
	update_list()

func update_list():
	var mtex = get_edited_object()
	var children = layer_list.get_children()
	var have = children.size()
	var want = mtex.get_depth() if mtex else 0
	
	for i in have:
		var ch = children[i]
		layer_list.remove_child(ch)
		ch.queue_free()
	
	for i in want:
		var layer = Layer.new()
		layer_list.add_child(layer)
		layer.idx = i
		layer.texarr = mtex
		layer.rect_min_size = Vector2(128, 128)
		layer.group = layer_group
		layer.connect("layer_set", self, "_on_layer_set")
		layer.main_button.connect("toggled", self, "_on_layer_toggled", [i])

func _enter_tree():
#	prints(get_tree().root.get_child(0).get_child(2).theme.get_stylebox("pressed", "Button"))
#	for ch in get_tree().root.get_child(0).get_children():
#		prints(ch)
	pass

func _ready():
	rect_min_size = Vector2(0, 1024)
	update_list()
	add_child(layer_list)
	add_child(create_button)
	add_child(create_dialog)
	set_bottom_editor(layer_list)

func _on_layer_toggled(on, i):
	if on:
		get_edited_object().selected = i
