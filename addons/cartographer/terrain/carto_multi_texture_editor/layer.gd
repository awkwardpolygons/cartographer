tool
extends CartoAxisLayout

const LayerPreview = preload("res://addons/cartographer/terrain/carto_multi_texture_editor/layer_preview.gd")
export(int) var idx: int setget set_idx
export(TextureArray) var texarr: TextureArray setget set_texarr
export(ButtonGroup) var group: ButtonGroup setget set_group
var main_button: Button
var file_dialog = EditorFileDialog.new()
var preview_buttons: VBoxContainer
var layer_preview
var channels_layout
var channels: CartoAxisLayout
var channel_option: OptionButton
var channel_option_box: HBoxContainer
var selected_channel: int

signal update_layer

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

func set_group(g):
	group = g
	if main_button:
		main_button.group = group

func _init():
	_init_file_dialog()
	
	layer_preview = LayerPreview.new()
	layer_preview.rect_min_size = Vector2(128, 128)
	_init_preview_buttons()
	layer_preview.add_child(preview_buttons)
	
	_init_channels()
	
	add_child(file_dialog)
	add_child(layer_preview)
	add_child(channels)

func _init_channels():
	var padding = 10
	var button_size = 32
	
	channels = CartoAxisLayout.new()
	channels.spacing = 10
	channels.pad_primary_start = 10
	channels.pad_primary_end = 20
	channels.pad_secondary_start = 30
	channels.pad_secondary_end = 30
	channels.visible = false
	
	for i in 4:
		var preview = LayerPreview.new()
		var load_button = Button.new()
		load_button.icon = preload("res://addons/cartographer/icons/icon_load.svg")
		load_button.rect_min_size = Vector2(button_size, button_size)
		load_button.margin_top = padding
		load_button.margin_left = padding
		load_button.connect("pressed", self, "_on_load", [i])
		preview.add_child(load_button)
		preview.rect_min_size = Vector2(128, 128)
		preview.channel = i
		channels.add_child(preview)

func _init_file_dialog():
	file_dialog.window_title = "Load image..."
	file_dialog.mode = EditorFileDialog.MODE_OPEN_FILE
	file_dialog.add_filter("*.png; PNG, *.jpg; JPEG, *.webp; WEBP, *.exr; EXR")
	file_dialog.connect("file_selected", self, "_on_file_selected")
	
	var file_dialog_box = file_dialog.get_vbox()
	channel_option_box = HBoxContainer.new()
	channel_option_box.alignment = BoxContainer.ALIGN_END
	var channel_option_label = Label.new()
	channel_option_label.text = "Choose the channel"
	
	channel_option = OptionButton.new()
	channel_option.add_item("RED", CartoTerrainMaterial.TextureChannel.RED)
	channel_option.add_item("GREEN", CartoTerrainMaterial.TextureChannel.GREEN)
	channel_option.add_item("BLUE", CartoTerrainMaterial.TextureChannel.BLUE)
	channel_option.add_item("ALPHA", CartoTerrainMaterial.TextureChannel.ALPHA)
	
	channel_option_box.add_child(channel_option_label)
	channel_option_box.add_child(channel_option)
	file_dialog_box.add_child(channel_option_box)

func _init_preview_buttons():
	var padding = 10
	var button_size = 32
	
	preview_buttons = VBoxContainer.new()
	preview_buttons.rect_min_size = Vector2(button_size, button_size)
	preview_buttons.grow_vertical = Control.GROW_DIRECTION_BEGIN
	preview_buttons.anchor_top = ANCHOR_END
	preview_buttons.anchor_bottom = ANCHOR_END
#	preview_buttons.margin_top = -button_size - padding
	preview_buttons.margin_bottom = -padding
	preview_buttons.anchor_left = ANCHOR_END
	preview_buttons.anchor_right = ANCHOR_END
	preview_buttons.margin_left = -button_size - padding
	preview_buttons.margin_right = -padding
	preview_buttons.add_constant_override("separation", padding)
	
	var more_button = Button.new()
	more_button.icon = preload("res://addons/cartographer/icons/icon_draw_opened.svg")
	more_button.rect_min_size = Vector2(button_size, button_size)
	more_button.toggle_mode = true
	more_button.connect("toggled", self, "_on_more")
	
	var load_button = Button.new()
	load_button.icon = preload("res://addons/cartographer/icons/icon_load.svg")
	load_button.rect_min_size = Vector2(button_size, button_size)
	load_button.connect("pressed", self, "_on_load", [-1])
	
	main_button = Button.new()
	main_button.anchor_bottom = ANCHOR_END
	main_button.anchor_right = ANCHOR_END
	main_button.toggle_mode = true
	var ns = StyleBoxEmpty.new()
	var sbh = StyleBoxFlat.new()
	sbh.bg_color = Color(0.1, 0.3, 0.8, 0.2)
	var sbp = StyleBoxFlat.new()
	sbp.bg_color = Color(0.1, 0.3, 0.8, 0.0)
	sbp.border_color = Color(0.1, 0.3, 0.8, 1)
	sbp.border_width_top = 3
	sbp.border_width_right = 3
	sbp.border_width_bottom = 3
	sbp.border_width_left = 3
	main_button.add_stylebox_override("normal", ns)
	main_button.add_stylebox_override("hover", sbh)
	main_button.add_stylebox_override("focus", ns)
	main_button.add_stylebox_override("pressed", sbp)
	main_button.group = group
	
	preview_buttons.add_child(load_button)
	preview_buttons.add_child(more_button)
	
	layer_preview.add_child(main_button)

func _on_more(visible):
	channels.visible = visible

func _on_load(chn):
	selected_channel = chn
	file_dialog.popup_centered_ratio()
	channel_option_box.visible = false if chn < 0 else true

func _on_file_selected(path):
	var prev = texarr.data
	var src = load(path)
	if selected_channel < 0:
		emit_signal("update_layer", [src, idx])
	else:
		var chn_src = channel_option.get_selected_id()
		var chn_dst = selected_channel
		emit_signal("update_layer", [src, idx, chn_src, chn_dst])

func get_preferred_size() -> Vector2:
	var size = .get_combined_minimum_size()
	size.x = rect_size.x
	size.y = rect_size.y
	return size
