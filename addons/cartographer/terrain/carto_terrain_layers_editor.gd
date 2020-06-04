tool
extends EditorProperty
class_name CartoTerrainLayersEditor

const MAX_LAYERS = 16
var prop_box
var file_dialog
var uv_scaler
var layers_buttons
var create_button
var load_button
var layers_tree
var dst_file_path = ""
var edfs: EditorFileSystem
var edited_obj

var import_tmpl = """
[remap]

importer="texture_array"
type="TextureArray"
metadata={
"imported_formats": [ "s3tc", "etc2" ],
"vram_texture": true
}

[deps]

source_file="{file_path}"

[params]

compress/mode=1
compress/no_bptc_if_rgb=false
flags/repeat=1
flags/filter=true
flags/mipmaps=true
flags/srgb=2
slices/horizontal={slices_h}
slices/vertical={slices_v}
"""

func _init():
	size_flags_horizontal = SIZE_EXPAND_FILL
	anchor_right = 1
	anchor_bottom = 1
	prop_box = VBoxContainer.new()
	prop_box.add_constant_override("separation", 8)
	file_dialog = EditorFileDialog.new()
	file_dialog.mode = EditorFileDialog.MODE_OPEN_FILES
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	uv_scaler = EditorSpinSlider.new()
	uv_scaler.label = "UV Scale"
	uv_scaler.min_value = 1
	uv_scaler.max_value = 100
	uv_scaler.flat = true
	layers_buttons = HBoxContainer.new()
	create_button = Button.new()
	create_button.text = "Create"
	create_button.size_flags_horizontal = SIZE_EXPAND_FILL
	create_button.connect("pressed", self, "_on_create")
	load_button = Button.new()
	load_button.text = "Load"
	load_button.size_flags_horizontal = SIZE_EXPAND_FILL
	load_button.connect("pressed", self, "_on_load")
	
	layers_tree = Tree.new()
	var root = layers_tree.create_item()
	layers_tree.set_hide_root(true)
	layers_tree.set_column_expand(0, true)
	layers_tree.connect("item_edited", self, "_layer_prop_changed")
	layers_tree.connect("item_selected", self, "_layer_selected")
	
	layers_buttons.add_child(create_button)
	layers_buttons.add_child(load_button)
	prop_box.add_child(file_dialog)
	prop_box.add_child(layers_buttons)
	prop_box.add_child(layers_tree)
	prop_box.add_child(uv_scaler)

func _on_load():
	file_dialog.window_title = "Load terrain textures"
	file_dialog.clear_filters()
	file_dialog.add_filter("*.png ; PNG Images")
	file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	file_dialog.connect("file_selected", self, "_on_load_selected", [], CONNECT_ONESHOT)
	file_dialog.popup_centered_ratio(0.45)

func _on_create():
	file_dialog.window_title = "Create terrain textures file location"
	file_dialog.clear_filters()
	file_dialog.add_filter("*.png ; PNG Images")
	file_dialog.mode = EditorFileDialog.MODE_SAVE_FILE
	file_dialog.connect("file_selected", self, "_on_dst_selected", [], CONNECT_ONESHOT)
	file_dialog.popup_centered_ratio(0.45)

func _on_load_selected(path):
	_load_array_file(path)

func _on_dst_selected(path):
	dst_file_path = path
	file_dialog.window_title = "Add terrain textures (max 16)"
	file_dialog.current_file = ""
	file_dialog.clear_filters()
	file_dialog.add_filter("*.png ; PNG Images")
	file_dialog.add_filter("*.jpg ; JPG Images")
	file_dialog.mode = EditorFileDialog.MODE_OPEN_FILES
	file_dialog.connect("files_selected", self, "_on_srcs_selected", [], CONNECT_ONESHOT)
	file_dialog.popup_centered_ratio(0.67)

func _on_srcs_selected(paths):
	_save_array_file(paths)

func _layer_prop_changed():
	var item = layers_tree.get_edited()
	var data = item.get_metadata(0)
	if data.prop == "use_triplanar":
		var on = item.is_checked(0)
		edited_obj.set_triplanar(data.layer, on)

func _layer_selected():
	var item = layers_tree.get_selected()
	var data = item.get_metadata(0)
	edited_obj.selected = data.layer

func _ready():
	edited_obj = get_edited_object().get(get_edited_property())
	edfs = Cartographer.editor.get_resource_filesystem()
	add_child(prop_box)
	set_bottom_editor(prop_box)
	
	if edited_obj.textures != null:
		_fill_layers_tree(edited_obj)

func _load_array_file(path):
	var res = load(path)
	if not res is TextureArray:
		return ERR_INVALID_DATA
	
	edited_obj.textures = res
	_fill_layers_tree(edited_obj)
	emit_changed(get_edited_property(), edited_obj, "textures")
	edited_obj.emit_signal("changed")

func _save_array_file(paths):
	var lth = len(paths)
	var mul = int(ceil(sqrt(lth)))
	var mulv = Vector2(mul, ceil(lth / mul))
	var src = load(paths[0]).get_data()
	var err = src.decompress()
	if err != OK:
		push_error("Error: Could not decompress image: %s" % err)
		return err
	var frmt = src.get_format()
	var size = src.get_size()
	var src_rect = Rect2(Vector2(0, 0), size)
	var dst = Vector2(0 ,0)
	var tot_size = mulv * size
	var img = Image.new()
	img.create(tot_size.x, tot_size.y, false, frmt)
	img.blit_rect(src, src_rect, dst)

	for i in range(1, min(MAX_LAYERS, lth)):
		src = load(paths[i]).get_data()
		err = src.decompress()
		dst.x = (i % mul) * size.x
		dst.y = floor(i / mul) * size.y
		img.blit_rect(src, src_rect, dst)

	img.save_png(dst_file_path)
#	edfs.connect("resources_reimported", self, "_temp", [], CONNECT_ONESHOT)
	_save_import_file({"file_path": dst_file_path, "slices_h": mulv.x, "slices_v": mulv.y})
	yield(edfs, "resources_reimported")
	prints("resources_reimported")
	_load_array_file(dst_file_path)

func _save_import_file(params: Dictionary):
	var s = import_tmpl.format(params)
#	prints(s)
	var f = File.new()
	var err = f.open("%s.import" % params.file_path, File.WRITE)
	if err != OK:
		f.close()
		return err
	f.store_string(s)
	f.close()
	edfs.scan()

func _clear_layers_tree():
	layers_tree.clear()
	var root = layers_tree.create_item()

func _fill_layers_tree(obj):
	_clear_layers_tree()
	var texarr = obj.textures
	var w = 128
	for i in texarr.get_depth():
		var tex = ImageTexture.new()
		tex.create_from_image(texarr.get_layer_data(i))
		var item = layers_tree.create_item()
		item.set_cell_mode(0, TreeItem.CELL_MODE_ICON)
		item.set_icon(0, tex)
		item.set_icon_max_width(0, w)
		item.collapsed = true
		item.set_metadata(0, {"prop": "root", "layer": i})
		if edited_obj.selected == i:
			item.select(0)
#		item.custom_minimum_height = 128
		var triplanar = layers_tree.create_item(item)
		triplanar.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		triplanar.set_text(0, "Use triplanar")
		triplanar.set_checked(0, edited_obj.get_triplanar(i))
		triplanar.set_selectable(0, false)
		triplanar.set_editable(0, true)
		triplanar.set_metadata(0, {"prop": "use_triplanar", "layer": i})
	layers_tree.rect_min_size = Vector2(w, w * texarr.get_depth() + w)
