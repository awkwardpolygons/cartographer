# BUG: emit_signal("changed") Needed because of https://github.com/godotengine/godot/issues/30179
tool
extends ShaderMaterial
class_name CartoTerrainMaterial

const MAX_LAYERS = 16
export(TextureArray) var textures setget _set_textures
export(ImageTexture) var mask_map: ImageTexture setget _set_mask_map
export(ImageTexture) var height_map: ImageTexture setget _set_height_map
export(Vector2) var uv1_scale: Vector2 = Vector2(1, 1) setget _set_uv1_scale
export(int) var use_triplanar: int = 0 setget _set_use_triplanar
export(int) var selected: int = 0
var sculptor: TexturePainter
var painter: TexturePainter

func _set_textures(ta):
	textures = ta
	set_shader_param("terrain_textures", textures)
	if mask_map == null and ta != null:
		create_mask_map()
	if height_map == null and ta != null:
		create_height_map()
#	property_list_changed_notify()
	emit_signal("changed")

func _set_mask_map(m):
	mask_map = m
	if m.get_size() == Vector2(0, 0):
		m.create(2048, 2048, Image.FORMAT_RGBA8)
	if painter:
		painter.texture = m
	set_shader_param("terrain_masks", get_mask_map())
	emit_signal("changed")

func _set_height_map(m):
	height_map = m
	if m.get_size() == Vector2(0, 0):
		m.create(2048, 2048, Image.FORMAT_RGBA8)
	if sculptor:
		sculptor.texture = m
	set_shader_param("terrain_height", get_height_map())
	emit_signal("changed")

func _set_uv1_scale(s):
	uv1_scale = s
	set_shader_param("uv1_scale", uv1_scale)
	emit_signal("changed")

func _set_use_triplanar(t):
	use_triplanar = t
	set_shader_param("use_triplanar", use_triplanar)
	emit_signal("changed")

func _init():
	shader = preload("res://addons/cartographer/terrain/terrain.shader")
	if Engine.is_editor_hint():
		sculptor = TexturePainter.new()
		sculptor.name = "Sculptor"
		painter = TexturePainter.new()
		painter.name = "Painter"

func get_mask_map():
	return mask_map if not painter else painter.get_texture()

func get_height_map():
	return height_map if not sculptor else sculptor.get_texture()

func calc_triplanar(idx: int, on: bool):
	var flag: int = pow(2, idx)
	if on:
		return use_triplanar | flag
	else:
		return use_triplanar & ~flag

func set_triplanar(idx: int, on: bool):
	_set_use_triplanar(calc_triplanar(idx, on))

func get_triplanar(idx: int) -> bool:
	var flag: int = pow(2, idx)
	return (use_triplanar & flag) > 0

func create_mask_map():
	var tex = ImageTexture.new()
	tex.create(2048, 2048, Image.FORMAT_RGBA8)
	_set_mask_map(tex)

func create_height_map():
	var tex = ImageTexture.new()
	tex.create(2048, 2048, Image.FORMAT_RGBA8)
	_set_height_map(tex)

func commit_painter():
	var img = painter.get_texture().get_data()
	mask_map.set_data(img)
#	mask_map.create_from_image(img)
	emit_signal("changed")

func commit_sculptor():
	var img = sculptor.get_texture().get_data()
	height_map.set_data(img)
#	height_map.create_from_image(img)
	emit_signal("changed")
