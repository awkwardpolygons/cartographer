tool
extends ShaderMaterial
class_name CartoTerrainMaterial2

enum TextureChannel {RED = 0, GREEN = 1, BLUE = 2, ALPHA = 3}
const MAX_LAYERS = 16
export(TextureArray) var albedo_textures setget _set_albedo_textures
export(TextureArray) var amr_textures setget _set_amr_textures # ao + metallic + roughness
export(TextureArray) var ndb_textures setget _set_ndb_textures # normal + depth + bump
export(ImageTexture) var weightmap: ImageTexture setget _set_weightmap
export(ImageTexture) var heightmap: ImageTexture setget _set_heightmap
export(Vector2) var uv1_scale: Vector2 = Vector2(1, 1) setget _set_uv1_scale
export(int) var selected: int = 0
var sculptor: TexturePainter
var painter: TexturePainter

func _set_albedo_textures(ta: TextureArray):
	albedo_textures = ta
	set_shader_param("albedo_textures", albedo_textures)
	emit_signal("changed")

func _set_amr_textures(ta: TextureArray):
	amr_textures = ta
	set_shader_param("amr_textures", amr_textures)
	emit_signal("changed")

func _set_ndb_textures(ta: TextureArray):
	ndb_textures = ta
	set_shader_param("ndb_textures", ndb_textures)
	emit_signal("changed")

func _set_weightmap(it: ImageTexture):
	weightmap = it
	set_shader_param("weightmap", get_weightmap())
	emit_signal("changed")

func _set_heightmap(it: ImageTexture):
	heightmap = it
	set_shader_param("heightmap", get_heightmap())
	emit_signal("changed")

func _set_uv1_scale(s):
	uv1_scale = s
	set_shader_param("uv1_scale", uv1_scale)
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
	if not weightmap:
		create_weightmap()
	var img = painter.get_texture().get_data()
	weightmap.set_data(img)
	emit_signal("changed")

func commit_sculptor():
	if not heightmap:
		create_heightmap()
	var img = sculptor.get_texture().get_data()
	img.convert(Image.FORMAT_RH)
	heightmap.set_data(img)
	emit_signal("changed")
