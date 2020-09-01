# BUG: emit_signal("changed") Needed because of https://github.com/godotengine/godot/issues/30179
tool
extends ShaderMaterial
class_name CartoTerrainMaterial

enum TextureChannel {RED = 0, GREEN = 1, BLUE = 2, ALPHA = 3}
const MAX_LAYERS = 16
export(TextureArray) var textures setget _set_textures
export(ImageTexture) var weightmap: ImageTexture setget _set_weightmap
export(ImageTexture) var heightmap: ImageTexture setget _set_heightmap
export(Vector2) var uv1_scale: Vector2 = Vector2(1, 1) setget _set_uv1_scale
export(int) var use_triplanar: int = 0 setget _set_use_triplanar
export(int) var selected: int = 0
var sculptor: TexturePainter
var painter: TexturePainter

func _set_textures(ta):
	textures = ta
	set_shader_param("albedo_textures", textures)
	if weightmap == null and ta != null:
		create_weightmap()
	if heightmap == null and ta != null:
		create_heightmap()
#	property_list_changed_notify()
	emit_signal("changed")

func _set_weightmap(m):
	weightmap = m
	if m.get_size() == Vector2(0, 0):
		m.create(2048, 2048, Image.FORMAT_RGBA8)
	if painter:
		painter.texture = m
	set_shader_param("weightmap", get_weightmap())
	emit_signal("changed")

func _set_heightmap(m):
	heightmap = m
	if m.get_size() == Vector2(0, 0):
		m.create(2048, 2048, Image.FORMAT_RGBA8)
	if sculptor:
		sculptor.texture = m
	set_shader_param("heightmap", get_heightmap())
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
	shader = preload("res://addons/cartographer/terrain/carto_terrain.shader")
	if Engine.is_editor_hint():
		sculptor = TexturePainter.new()
		sculptor.hdr = true
		sculptor.usage = Viewport.USAGE_3D
		sculptor.name = "Sculptor"
		painter = TexturePainter.new()
		painter.name = "Painter"

func get_weightmap():
	return weightmap if not painter else painter.get_texture()

func get_heightmap():
	return heightmap if not sculptor else sculptor.get_texture()

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

func create_weightmap():
	var tex = ImageTexture.new()
	var img = Image.new()
	img.create(2048, 2048, false, Image.FORMAT_RGBA8)
	tex.create_from_image(img)
	_set_weightmap(tex)

func create_heightmap():
	var tex = ImageTexture.new()
	tex.create(2048, 2048, Image.FORMAT_RH)
	_set_heightmap(tex)

func commit_painter():
	var img = painter.get_texture().get_data()
	weightmap.set_data(img)
#	weightmap.create_from_image(img)
	emit_signal("changed")

func commit_sculptor():
	var img = sculptor.get_texture().get_data()
	img.convert(Image.FORMAT_RH)
	heightmap.set_data(img)
#	heightmap.create_from_image(img)
	emit_signal("changed")
