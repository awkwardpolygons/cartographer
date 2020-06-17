tool
extends VBoxContainer

var group: ButtonGroup
var layers

signal property_set_value

func _init():
	alignment = BoxContainer.ALIGN_CENTER
	group = ButtonGroup.new()
	rect_min_size = Vector2(0, 160)

func bind(layers):
	if not (layers and layers.textures):
		resize(0)
		return
	self.layers = layers
	var size = layers.textures.get_depth()
	resize(size)
	
	for i in size:
		set_item(i, layers)

func resize(size: int):
	var cur_size = get_child_count()
	var children = get_children()
	
	for i in range(size - cur_size):
		add_item()
	
	for i in range(size, cur_size):
		remove_child(children[i])

func add_item(layers=null):
	var item = VBoxContainer.new()
	var thumb = Button.new()
	thumb.name= "Thumb"
	thumb.size_flags_horizontal = SIZE_EXPAND_FILL
	thumb.flat = true
	thumb.toggle_mode = true
	thumb.group = group
	thumb.connect("toggled", self, "_on_toggled", [item])
	var triplanar = CheckBox.new()
	triplanar.text = "Use triplanar texturing"
	triplanar.name = "UseTriplanar"
	triplanar.visible = false
	triplanar.margin_left = 8
	triplanar.connect("toggled", self, "_on_triplanar", [item])
	item.add_child(thumb)
	item.add_child(triplanar)
	add_child(item)
	if layers:
		set_item(get_child_count(), layers)

func set_item(idx, layers):
	var item = get_child(idx)
	item.set_meta("idx", idx)
	var thumb = item.get_node("Thumb")
	thumb.icon = get_icon_from(idx, layers.textures)
	var triplanar = item.get_node("UseTriplanar")
	triplanar.pressed = layers.get_triplanar(idx)

func get_icon_from(idx: int, texarr: TextureArray):
	var tex = ImageTexture.new()
	var img = texarr.get_layer_data(idx)
	img.resize(160, 160, Image.INTERPOLATE_BILINEAR)
	tex.create_from_image(img, Texture.FLAGS_DEFAULT)
	return tex

func _on_toggled(toggled, item):
	var idx = item.get_meta("idx")
	item.get_node("UseTriplanar").visible = toggled
	if toggled:
		layers.selected = idx

func _on_triplanar(toggled, item):
	var idx = item.get_meta("idx")
#	layers.set_triplanar(idx, toggled)
	emit_signal("property_set_value", "use_triplanar", layers.calc_triplanar(idx, toggled))
