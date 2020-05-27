tool
extends MeshInstance
class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

export(Vector3) var size: Vector3 = Vector3(256, 64, 256) setget _set_size
export(Resource) var terrain_layers

var terrain: MeshInstance = self
var bounds: CartoTerrainBounds
var mask_painter: TexturePainter setget , _get_mask_painter
var height_painter: TexturePainter setget , _get_height_painter
var data_dir: Directory setget , _get_data_dir
var _shader = preload("res://addons/cartographer/terrain/terrain.shader")

func _set_size(s: Vector3):
	size = s
	bounds.reset(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	set_custom_aabb(bounds._aabb)
#	if terrain.mesh:
#		terrain.mesh.size = Vector2(s.x, s.z)
#	if terrain.material_override:
#		terrain.material_override.set_shader_param("terrain_size", s)

func _get_mask_painter():
	if not mask_painter:
		if has_node("MaskPainter"):
			mask_painter = get_node("MaskPainter")
	return mask_painter

func _get_height_painter():
	if not height_painter:
		if has_node("HeightPainter"):
			height_painter = get_node("HeightPainter")
	return height_painter

func _get_data_dir():
	if data_dir != null:
		return data_dir
	if not has_meta("uid"):
		return null
	var id = get_meta("uid")
	var data_part = "res://addons/cartographer/data/"
	var terrain_part = "terrain_%s/" % id
	var path = data_part + terrain_part
	data_dir = Directory.new()
	data_dir.open(data_part)
	if not data_dir.dir_exists(terrain_part):
		data_dir.make_dir(terrain_part)
	data_dir.open(path)
	return data_dir

func _init():
	bounds = CartoTerrainBounds.new(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	# A custom AABB is needed because vertices are offset by the GPU
	set_custom_aabb(bounds._aabb)

var _inst
var _mesh
func _enter_tree():
	if not has_meta("uid"):
		# TODO: Improve this UID generator
		set_meta("uid", hash([OS.get_unique_id(), OS.get_unix_time(), randi()]) % 999999)
	
	terrain_layers = CartoTerrainLayers.new(self.data_dir.get_current_dir())
	_init_mesh()
	_init_material()
	if Engine.is_editor_hint():
		_init_painters()

func _init_mesh():
	if terrain.mesh == null:
		print("PlaneMesh.new()")
		var mesh = load("res://addons/cartographer/meshes/clipmap_256.obj")
		terrain.mesh = mesh

func _init_material():
	if terrain.material_override == null:
		print("ShaderMaterial.new()")
		terrain.material_override = ShaderMaterial.new()
		terrain.material_override.shader = _shader
		terrain.material_override.set_shader_param("terrain_textures", terrain_layers.textures)

func _init_painters():
	_init_mask_painter()
	_init_height_painter()
	if terrain.material_override:
		terrain.material_override.set_shader_param("terrain_size", size)
		terrain.material_override.set_shader_param("terrain_masks", mask_painter.get_texture())
		terrain.material_override.set_shader_param("terrain_height", height_painter.get_texture())

func _init_mask_painter():
	if not mask_painter:
		print("TexturePainter.new()")
		mask_painter = TexturePainter.new()
		mask_painter.name = "MaskPainter"
		terrain.add_child(mask_painter)

func _init_height_painter():
	if not height_painter:
		print("TexturePainter.new()")
		height_painter = TexturePainter.new()
#		height_painter.hdr = true
		height_painter.name = "HeightPainter"
		terrain.add_child(height_painter)

func paint_masks(action: int, pos: Vector2):
	if not mask_painter:
		return
	mask_painter.paint_masks(action, pos, terrain_layers.selected)

func paint_height(action: int, pos: Vector2):
	if not height_painter:
		return
	height_painter.paint_height(action, pos)

func intersect_ray(from: Vector3, dir: Vector3):
#	var hmap = ImageTexture.new()
#	var img = Image.new()
#	img.create(1024, 1024, Image.FORMAT_RGBA8, 0)
#	img.fill(Color(0, 0, 0, 1))
#	hmap.create_from_image(img)
	var hmap = height_painter.get_texture()
	from = transform.xform_inv(from)
	return bounds.intersect_ray(from, dir, hmap)
