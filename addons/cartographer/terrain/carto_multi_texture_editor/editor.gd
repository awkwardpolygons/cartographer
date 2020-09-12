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

#func _gui_input(event):
#	if event is InputEventMouseButton:
#		_on_create_acknowledged(true, [1024, 1024, 4, Image.FORMAT_RGBA8])

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
#	prints(get_edited_object(), get_edited_object().data, get_edited_property(), texarr)
	pass

func _exit_tree():
	create_dialog.disconnect("acknowledged", self, "_on_create_acknowledged")
	create_button.disconnect("pressed", self, "_on_create_pressed")

func _ready():
	rect_min_size = Vector2(0, 256)
	add_child(layer_list)
	add_child(create_button)
	add_child(create_dialog)
	set_bottom_editor(layer_list)

func update_property():
	update_list()

func _on_create_pressed():
	create_dialog.popup_centered(Vector2(400, 200))

func _on_create_acknowledged(ok, vals):
	var data = texarr.create_data(vals[0], vals[1], vals[2], vals[3], Texture.FLAGS_DEFAULT)
#	var data = {
#		"width": vals[0],
#		"height": vals[1],
#		"depth": vals[2],
#		"format": vals[3],
#		"flags": Texture.FLAGS_DEFAULT,
#		"layers": [],
#	}
	if not ok or not texarr:
		return
#	texarr.create(vals[0], vals[1], vals[2], vals[3], Texture.FLAGS_DEFAULT)
	
	for i in vals[2]:
		var img = Image.new()
		img.create(vals[0], vals[1], true, vals[3])
		img.fill(Color(0, 1, 1, 1))
		img.generate_mipmaps()
		data.layers.append(img)
	
	emit_changed("redata", data)
	update_property()

func _on_layer_toggled(on, i):
	if on:
		texarr.selected = i

# Use a static reference for the do / undo methods because the editor might unload
# this instance.
func _on_update_layer(layer):
	undo_redo.create_action("Update layer")
	undo_redo.add_do_method(get_script(), "_do_layer_update", texarr, layer)
	undo_redo.add_undo_method(get_script(), "_do_layer_update", texarr, [texarr.get_layer(layer[1]), layer[1]])
	undo_redo.commit_action()

static func _do_layer_update(ta, layer):
	ta.callv("set_layer", layer)
