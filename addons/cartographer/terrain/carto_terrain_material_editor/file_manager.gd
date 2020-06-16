tool
extends HBoxContainer

const MAX_LAYERS = 16
var file_dialog: EditorFileDialog
var current_dir: String
var file_path: String
var new_button: Button
var load_button: Button
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

signal created
signal loaded

func _init():
	size_flags_horizontal = SIZE_EXPAND_FILL
	add_constant_override("separation", 1)
	file_dialog = EditorFileDialog.new()
	file_dialog.mode = EditorFileDialog.MODE_OPEN_FILES
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	current_dir = file_dialog.current_dir
	new_button = Button.new()
	new_button.text = "New"
	new_button.size_flags_horizontal = SIZE_EXPAND_FILL
	new_button.connect("pressed", self, "_on_new")
	load_button = Button.new()
	load_button.text = "Load"
	load_button.size_flags_horizontal = SIZE_EXPAND_FILL
	load_button.connect("pressed", self, "_on_load")
	add_child(file_dialog)
	add_child(new_button)
	add_child(load_button)

func _on_new():
	file_dialog.current_dir = current_dir
	file_dialog.current_file = ""
	file_dialog.window_title = "Create terrain textures file"
	file_dialog.clear_filters()
	file_dialog.add_filter("*.png ; PNG Images")
	file_dialog.mode = EditorFileDialog.MODE_SAVE_FILE
	file_dialog.connect("file_selected", self, "_after_new", [], CONNECT_ONESHOT)
	file_dialog.popup_centered_ratio(0.45)

func _after_new(path):
	current_dir = file_dialog.current_dir
	file_path = path
	file_dialog.window_title = "Select terrain textures (max %s)" % MAX_LAYERS
	file_dialog.clear_filters()
	file_dialog.add_filter("*.png ; PNG Images")
	file_dialog.add_filter("*.jpg ; JPG Images")
	file_dialog.mode = EditorFileDialog.MODE_OPEN_FILES
	file_dialog.connect("files_selected", self, "_do_create", [], CONNECT_ONESHOT)
	file_dialog.popup_centered_ratio(0.67)

func _do_create(paths):
	var lth = len(paths)
	if lth <= 0:
		return
	var cols = int(ceil(sqrt(lth)))
	var rows = ceil(lth / cols)
	var cols_rows = Vector2(cols, rows)
	var src = load(paths[0])
	var size = src.get_size()
	var src_rect = Rect2(Vector2(0, 0), size)
	var dst = Vector2(0 ,0)
	var tot_size = cols_rows * size
	var img = Image.new()
	img.create(tot_size.x, tot_size.y, false, Image.FORMAT_RGBA8)
	var err

	for i in range(min(MAX_LAYERS, lth)):
		src = load(paths[i]).get_data()
		err = src.decompress()
		if err:
			push_error("Error: Could not decompress image: %s" % err)
			return err
		dst.x = (i % cols) * size.x
		dst.y = floor(i / cols) * size.y
		img.blit_rect(src, src_rect, dst)

	img.save_png(file_path)
#	edfs.connect("resources_reimported", self, "_temp", [], CONNECT_ONESHOT)
	_save_import_file({"file_path": file_path, "slices_h": cols, "slices_v": rows})
	emit_signal("created", file_path)

func _save_import_file(params: Dictionary):
	var s = import_tmpl.format(params)
	var f = File.new()
	var err = f.open("%s.import" % params.file_path, File.WRITE)
	if err != OK:
		push_error("Error: Could not save import file: %s" % err)
		f.close()
		return err
	f.store_string(s)
	f.close()

func _on_load():
	file_dialog.current_dir = current_dir
	file_dialog.current_file = ""
	file_dialog.window_title = "Load terrain textures file"
	file_dialog.clear_filters()
	file_dialog.add_filter("*.png ; PNG Images")
	file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	file_dialog.connect("file_selected", self, "_do_load", [], CONNECT_ONESHOT)
	file_dialog.popup_centered_ratio(0.45)

func _do_load(path):
	current_dir = file_dialog.current_dir
	emit_signal("loaded", path)
