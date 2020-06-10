tool
extends EditorProperty

const FileManager = preload("res://addons/cartographer/terrain/carto_terrain_layers_editor/file_manager.gd")
const LayersList = preload("res://addons/cartographer/terrain/carto_terrain_layers_editor/layers_list.gd")
var prop_box: VBoxContainer
var file_manager: FileManager
var layers_tree: Tree
var layers_list: LayersList
var edited_obj
var edfs

func _init():
	prop_box = VBoxContainer.new()
	prop_box.add_constant_override("separation", 4)
	file_manager = FileManager.new()
	file_manager.connect("created", self, "_on_created")
	file_manager.connect("loaded", self, "_on_loaded")
	layers_tree = Tree.new()
	var root = layers_tree.create_item()
	layers_tree.set_hide_root(true)
	layers_tree.set_column_expand(0, true)
	layers_tree.connect("item_edited", self, "_layer_prop_changed")
	layers_tree.connect("item_selected", self, "_layer_selected")
	layers_tree.add_stylebox_override("bg", StyleBoxEmpty.new())
	layers_tree.add_stylebox_override("bg_focus", StyleBoxEmpty.new())
	
	layers_list = LayersList.new()
	layers_list.connect("property_set_value", self, "emit_changed")
	
	prop_box.add_child(file_manager)
#	prop_box.add_child(layers_tree)
	prop_box.add_child(layers_list)

func _ready():
	edited_obj = get_edited_object()
	edfs = Cartographer.editor.get_resource_filesystem()
	add_child(prop_box)
	set_bottom_editor(prop_box)

func _on_created(path):
	edfs.connect("resources_reimported", self, "_on_loaded", [], CONNECT_ONESHOT)
	edfs.scan()

func _on_loaded(path):
	path = path[0] if path is PoolStringArray else path
	prints(path)
	var res = load(path)
	if not res is TextureArray:
		return ERR_INVALID_DATA
	
	emit_changed("textures", res)
#	edited_obj.emit_signal("changed")

func update_property():
	prints("update_property")
	layers_list.bind(edited_obj)
	edited_obj.emit_signal("changed")
