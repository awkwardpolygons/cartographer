tool
extends CartoAxisLayout

const LayerPreview = preload("res://addons/cartographer/terrain/carto_multi_texture_editor/layer_preview.gd")
export(int) var idx: int setget set_idx
export(TextureArray) var texarr: TextureArray setget set_texarr
var file_dialog = EditorFileDialog.new()
var load_button: Button
var more_button: Button
var button_layout: VBoxContainer
var layer_preview
var channels_layout
var channels: CartoAxisLayout

func set_idx(i):
	idx = i
	layer_preview.idx = idx
	for ch in channels.get_children():
		ch.idx = idx

func set_texarr(ta):
	texarr = ta
	layer_preview.texarr = texarr
	for ch in channels.get_children():
		ch.texarr = texarr

func _init():
	file_dialog.window_title = "Load image..."
	file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	file_dialog.add_filter("*.png; PNG, *.jpg; JPEG, *.webp; WEBP, *.exr; EXR")
	file_dialog.connect("file_selected", self, "_on_selected")
	
	rect_clip_content = true
	var padding = 10
	var button_size = 32
	
	layer_preview = LayerPreview.new()
	layer_preview.rect_min_size = Vector2(128, 128)

	more_button = Button.new()
	more_button.icon = preload("res://addons/cartographer/icons/icon_draw_opened.svg")
	more_button.rect_min_size = Vector2(button_size, button_size)
	more_button.toggle_mode = true
	more_button.connect("toggled", self, "_on_more")
	
	load_button = Button.new()
	load_button.icon = preload("res://addons/cartographer/icons/icon_load.svg")
	load_button.rect_min_size = Vector2(button_size, button_size)
	load_button.connect("pressed", self, "_on_load")
	
	button_layout = VBoxContainer.new()
	button_layout.rect_min_size = Vector2(button_size, button_size)
	button_layout.grow_vertical = Control.GROW_DIRECTION_BEGIN
	button_layout.anchor_top = ANCHOR_END
	button_layout.anchor_bottom = ANCHOR_END
#	button_layout.margin_top = -button_size - padding
	button_layout.margin_bottom = -padding
	button_layout.anchor_left = ANCHOR_END
	button_layout.anchor_right = ANCHOR_END
	button_layout.margin_left = -button_size - padding
	button_layout.margin_right = -padding
	button_layout.add_constant_override("separation", padding)
	
	button_layout.add_child(load_button)
	button_layout.add_child(more_button)
	
	layer_preview.add_child(button_layout)
	
	channels = CartoAxisLayout.new()
	channels.spacing = 10
	channels.pad_primary_start = 10
	channels.pad_primary_end = 20
	channels.pad_secondary_start = 30
	channels.pad_secondary_end = 30
	channels.visible = false
	
	for i in 4:
		var ch = LayerPreview.new()
		channels.add_child(ch)
		ch.rect_min_size = Vector2(128, 128)
		ch.channel = pow(2, i)
	
	add_child(file_dialog)
	add_child(layer_preview)
	add_child(channels)

func _on_more(visible):
	channels.visible = visible

func _on_load():
	file_dialog.popup_centered_ratio()

func _on_selected(path):
	var src = load(path)
	texarr.set_layer(src, idx)

func get_preferred_size() -> Vector2:
	var size = .get_combined_minimum_size()
	size.x = rect_size.x
	size.y = rect_size.y
	return size
