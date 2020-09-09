tool
extends ShaderMaterial
class_name CartoTerrainMaterial

enum TextureChannel {RED = 0, GREEN = 1, BLUE = 2, ALPHA = 3}
const MAX_LAYERS = 16

var albedo_colors: PoolColorArray
var albedo_textures: TextureArray setget _set_albedo_textures
var orm_textures: TextureArray setget _set_orm_textures
#var ao_textures: TextureArray setget _set_ao_textures
#var depth_textures: TextureArray setget _set_depth_textures
#var metallic_textures: TextureArray setget _set_metallic_textures
var normal_textures: TextureArray setget _set_normal_textures
#var roughness_textures: TextureArray setget _set_roughness_textures

var weightmap: ImageTexture setget _set_weightmap
var heightmap: ImageTexture setget _set_heightmap
var uv1_scale: Vector2 = Vector2(1, 1) setget _set_uv1_scale
var selected: int = 0
var sculptor: TexturePainter
var painter: TexturePainter

func _set_albedo_textures(ta: TextureArray):
	if ta and not ta is CartoMultiTexture:
		ta.set_script(preload("res://addons/cartographer/terrain/carto_multi_texture.gd"))
	if albedo_textures and albedo_textures.has_signal("changed"):
		albedo_textures.disconnect("changed", self, "_on_layer_selected")
	albedo_textures = ta
	set_shader_param("albedo_textures", albedo_textures)
	if albedo_textures:
		albedo_textures.connect("changed", self, "_on_layer_selected", [ta])
	emit_signal("changed")

func _set_orm_textures(ta: TextureArray):
	orm_textures = ta
	set_shader_param("orm_textures", orm_textures)
	emit_signal("changed")

#func _set_ao_textures(ta: TextureArray):
#	ao_textures = ta
#	set_shader_param("ao_textures", ao_textures)
#	emit_signal("changed")
#
#func _set_depth_textures(ta: TextureArray):
#	depth_textures = ta
#	set_shader_param("depth_textures", depth_textures)
#	emit_signal("changed")
#
#func _set_metallic_textures(ta: TextureArray):
#	metallic_textures = ta
#	set_shader_param("metallic_textures", metallic_textures)
#	emit_signal("changed")
#
func _set_normal_textures(ta: TextureArray):
	normal_textures = ta
	set_shader_param("normal_textures", normal_textures)
	emit_signal("changed")
#
#func _set_roughness_textures(ta: TextureArray):
#	roughness_textures = ta
#	set_shader_param("roughness_textures", roughness_textures)
#	emit_signal("changed")

func _set_weightmap(m: ImageTexture):
	weightmap = m
	if painter:
		painter.texture = m
	set_shader_param("weightmap", get_weightmap())
	emit_signal("changed")

func _set_heightmap(m: ImageTexture):
	heightmap = m
	if sculptor:
		sculptor.texture = m
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

func _on_layer_selected(ta):
	selected = ta.selected

func _get_property_list():
	var properties = []
	properties.append(_prop_group("Albedo", "albedo_"))
	properties.append(_prop_info("albedo_colors", TYPE_COLOR_ARRAY))
	properties.append(_prop_info("albedo_textures", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "TextureArray"))
	
	properties.append(_prop_group("AO, Roughness, Metallic", "orm_"))
	properties.append(_prop_info("orm_textures", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "TextureArray"))

#	properties.append(_prop_group("Metallic", "metallic_"))
#	properties.append(_prop_info("metallic_textures", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "TextureArray"))
#
#	properties.append(_prop_group("Roughness", "roughness_"))
#	properties.append(_prop_info("roughness_textures", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "TextureArray"))
#
	properties.append(_prop_group("Normal Map", "normal_"))
	properties.append(_prop_info("normal_textures", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "TextureArray"))
#
#	properties.append(_prop_group("Ambient Occlusion", "ao_"))
#	properties.append(_prop_info("ao_textures", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "TextureArray"))
#
#	properties.append(_prop_group("Depth", "depth_"))
#	properties.append(_prop_info("depth_textures", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "TextureArray"))
	
	properties.append(_prop_info("heightmap", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "ImageTexture"))
	properties.append(_prop_info("weightmap", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "ImageTexture"))
	properties.append(_prop_info("uv1_scale", TYPE_VECTOR2))
	return properties

func _prop_group(name: String, prefix: String) -> Dictionary:
	return {
		name = name,
		type = TYPE_NIL,
		hint_string = prefix,
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_CATEGORY
	}

func _prop_info(name: String, type: int, hint: int = PROPERTY_HINT_NONE, hint_string: String = "") -> Dictionary:
	return {
		name = name,
		type = type,
		hint = hint,
		hint_string = hint_string,
		usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
	}
