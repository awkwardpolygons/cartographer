tool
extends ShaderMaterial
class_name CartoTerrainMaterial

enum TextureChannel {RED = 0, GREEN = 1, BLUE = 2, ALPHA = 3}
const MAX_LAYERS = 16

var albedo_colors: PoolColorArray
var albedo_textures: TextureArray setget set_albedo_textures
var orm_textures: TextureArray setget set_orm_textures
var normal_textures: TextureArray setget set_normal_textures

var normal_enabled: int = 0 setget set_normal_enabled
var normal_scale: float = 1 setget set_normal_scale
var orm_light_affect: float = 0 setget set_orm_light_affect
var orm_roughness: float = 1 setget set_orm_roughness
var orm_metallic: float = 0 setget set_orm_metallic
var orm_specular: float = 0.5 setget set_orm_specular

var weightmap: ImageTexture setget set_weightmap
var heightmap: ImageTexture setget set_heightmap

var uv1_scale: Vector3 = Vector3(1, 1, 1) setget set_uv1_scale
var uv1_offset: Vector3 = Vector3(0, 0, 0) setget set_uv1_offset
var uv1_triplanar: int = 0 setget set_uv1_triplanar
var uv1_triplanar_sharpness: float = 2 setget set_uv1_triplanar_sharpness
var selected: int = 0
var sculptor: TexturePainter
var painter: TexturePainter
var _layers: String = "Layer1,Layer2,Layer3,Layer4,Layer4,Layer5,Layer6,Layer7,Layer8,Layer9,Layer10,Layer11,Layer12,Layer13,Layer14,Layer15,Layer16"

func set_albedo_textures(ta: TextureArray):
	albedo_textures = _prep_textures("albedo_textures", ta, albedo_textures)

func set_orm_textures(ta: TextureArray):
	orm_textures = _prep_textures("orm_textures", ta, orm_textures)

func set_normal_textures(ta: TextureArray):
	normal_textures = _prep_textures("normal_textures", ta, normal_textures)

func _prep_textures(name: String, new: TextureArray, old: TextureArray):
#	prints("_prep_textures:", name, new, old)
	if old and old.has_signal("changed"):
		old.disconnect("changed", self, "_on_layer_changed")
	if new:
		if not new is CartoMultiTexture:
			new.set_script(preload("res://addons/cartographer/terrain/carto_multi_texture.gd"))
		new.connect("changed", self, "_on_layer_changed", [name, new])
	
	_on_layer_changed(name, new)
	return new

func set_normal_enabled(v):
	normal_enabled = v
	set_shader_param("normal_enabled", v)

func set_normal_scale(v):
	normal_scale = v
	set_shader_param("normal_scale", v)

func set_orm_light_affect(v):
	orm_light_affect = v
	set_shader_param("ao_light_affect", v)

func set_orm_roughness(v):
	orm_roughness = v
	set_shader_param("roughness", v)

func set_orm_metallic(v):
	orm_metallic = v
	set_shader_param("metallic", v)

func set_orm_specular(v):
	orm_specular = v
	set_shader_param("specular", v)

func set_weightmap(m: ImageTexture):
	weightmap = m
	if painter:
		painter.texture = m
	set_shader_param("weightmap", get_weightmap())
	emit_signal("changed")

func set_heightmap(m: ImageTexture):
	heightmap = m
	if sculptor:
		sculptor.texture = m
	set_shader_param("heightmap", get_heightmap())
	emit_signal("changed")

func set_uv1_scale(v):
	uv1_scale = v
	set_shader_param("uv1_scale", uv1_scale)
	emit_signal("changed")

func set_uv1_offset(v):
	uv1_offset = v
	set_shader_param("uv1_offset", uv1_offset)
	emit_signal("changed")

func set_uv1_triplanar(v):
	uv1_triplanar = v
	set_shader_param("uv1_triplanar", uv1_triplanar)
	emit_signal("changed")

func set_uv1_triplanar_sharpness(v):
	uv1_triplanar_sharpness = v
	set_shader_param("uv1_triplanar_sharpness", uv1_triplanar_sharpness)
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
	set_weightmap(tex)

func create_heightmap():
	var tex = ImageTexture.new()
	tex.create(2048, 2048, Image.FORMAT_RH)
	set_heightmap(tex)

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

func _on_layer_changed(name, ta):
#	prints("_on_layer_changed", name, ta)
	if ta:
		selected = ta.selected
		if ta.get_depth() > 0:
			set_shader_param(name, ta)
	else:
		set_shader_param(name, null)
	emit_signal("changed")

func _get_property_list():
	var properties = []
	properties.append(_prop_group("Albedo", "albedo_"))
	properties.append(_prop_info("albedo_colors", TYPE_COLOR_ARRAY))
	properties.append(_prop_info("albedo_textures", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "TextureArray"))
	
	properties.append(_prop_group("AO, Roughness, Metallic", "orm_"))
	properties.append(_prop_info("orm_light_affect", TYPE_REAL, PROPERTY_HINT_RANGE, "0,1"))
	properties.append(_prop_info("orm_roughness", TYPE_REAL, PROPERTY_HINT_RANGE, "0,1"))
	properties.append(_prop_info("orm_metallic", TYPE_REAL, PROPERTY_HINT_RANGE, "0,1"))
	properties.append(_prop_info("orm_specular", TYPE_REAL, PROPERTY_HINT_RANGE, "0,1"))
	properties.append(_prop_info("orm_textures", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "TextureArray"))
	
	properties.append(_prop_group("Normal Map", "normal_"))
	properties.append(_prop_info("normal_enabled", TYPE_INT, PROPERTY_HINT_FLAGS, _layers))
	properties.append(_prop_info("normal_scale", TYPE_REAL, PROPERTY_HINT_RANGE, "-16,16"))
	properties.append(_prop_info("normal_textures", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "TextureArray"))
	
	properties.append(_prop_group("UV1", "uv1_"))
	properties.append(_prop_info("uv1_scale", TYPE_VECTOR3))
	properties.append(_prop_info("uv1_offset", TYPE_VECTOR3))
	properties.append(_prop_info("uv1_triplanar", TYPE_INT, PROPERTY_HINT_FLAGS, _layers))
	properties.append(_prop_info("uv1_triplanar_sharpness", TYPE_REAL, PROPERTY_HINT_EXP_EASING))
	
	properties.append(_prop_info("heightmap", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "ImageTexture"))
	properties.append(_prop_info("weightmap", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "ImageTexture"))
	
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
