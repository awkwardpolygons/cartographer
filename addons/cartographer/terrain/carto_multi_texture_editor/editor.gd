tool
extends EditorProperty

const CreateDialog = preload("res://addons/cartographer/terrain/carto_multi_texture_editor/create_dialog.tscn")
const Layer = preload("res://addons/cartographer/terrain/carto_multi_texture_editor/layer.gd")
var texarr
var undo_redo
var layer_list: CartoAxisLayout
var layer_group: ButtonGroup
var create_button: Button
var create_dialog: WindowDialog

func _init():
	label = "Layers"
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
	create_button.connect("pressed", self, "_on_create_pressed")
	
	create_dialog = CreateDialog.instance()
	create_dialog.connect("acknowledged", self, "_on_create_acknowledged")

func update_list():
	var children = layer_list.get_children()
	var have = children.size()
	var want = texarr.get_depth() if texarr else 0
	
	for i in have:
		var ch = children[i]
		layer_list.remove_child(ch)
		ch.disconnect("update_layer", self, "_on_update_layer")
		ch.main_button.disconnect("toggled", self, "_on_layer_toggled")
		ch.queue_free()
	
	for i in want:
		var layer = Layer.new()
		layer_list.add_child(layer)
		layer.idx = i
		layer.texarr = texarr
		layer.rect_min_size = Vector2(128, 128)
		layer.group = layer_group
		layer.connect("update_layer", self, "_on_update_layer")
		layer.main_button.connect("toggled", self, "_on_layer_toggled", [i])

func _enter_tree():
#	prints(get_tree().root.get_child(0).get_child(2).theme.get_stylebox("pressed", "Button"))
#	for ch in get_tree().root.get_child(0).get_children():
#		prints(ch)
	pass

func _ready():
	rect_min_size = Vector2(0, 1024)
	add_child(layer_list)
	add_child(create_button)
	add_child(create_dialog)
	set_bottom_editor(layer_list)

func update_property():
	update_list()

func _on_create_pressed():
	create_dialog.popup_centered(Vector2(400, 200))

func _on_create_acknowledged(ok, vals):
	var mtex = get_edited_object()
	var data = mtex.create_data(vals[0], vals[1], vals[2], vals[3], Texture.FLAGS_DEFAULT)
	if not ok or not mtex:
		return
	
	for i in vals[2]:
		var img = Image.new()
		img.create(vals[0], vals[1], true, vals[3])
		img.fill(Color(0, 0, 0, 0))
		img.generate_mipmaps()
		data.layers.append(img)
	
	emit_changed("data", data)

func _on_update_layer(layer):
	var texarr = get_edited_object()
	var undo_redo = Cartographer.undo_redo
	undo_redo.create_action("Update layer")
	undo_redo.add_do_method(self, "_do_layer_update", layer)
	undo_redo.add_undo_method(self, "_do_layer_update", [texarr.get_layer(layer[1]), layer[1]])
	undo_redo.commit_action()

func _do_layer_update(layer):
	get_edited_object().callv("set_layer", layer)

func _on_layer_toggled(on, i):
	if on:
		get_edited_object().selected = i
