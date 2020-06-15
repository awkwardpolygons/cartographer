tool
extends MeshInstance
class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

const shader = preload("res://addons/cartographer/terrain/terrain.shader")
export(float, 32, 1024, 32) var width: float = 256 setget _set_width
export(float, 32, 1024, 32) var depth: float = 256 setget _set_depth
export(float, 32, 1024, 32) var height: float = 64 setget _set_height
export(ImageTexture) var height_map: ImageTexture setget set_height_map
export(Resource) var terrain_layers
var size: Vector3 = Vector3(256, 64, 256) setget _set_size
var mesh_size: float
var square_size: float = max(size.x, size.z)
var bounds: CartoTerrainBounds
var sculptor: TexturePainter
var painter: TexturePainter
var brush: PaintBrush

func _set_width(w: float):
	width = w
	self.size = Vector3(w, size.y, size.z)

func _set_depth(d: float):
	depth = d
	self.size = Vector3(size.x, size.y, d)

func _set_height(h: float):
	height = h
	self.size = Vector3(size.x, h, size.z)

func _set_size(s):
	prints("_set_size")
	size = s
	_update_bounds()
	square_size = max(size.x, size.z)
	var ms = 256 if square_size <= 256 else 512 if square_size <= 512 else 1024
	if mesh == null or ms != mesh_size:
		_init_mesh()

func _update_bounds():
	bounds.reset(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	# A custom AABB is needed because vertices are offset by the GPU
	set_custom_aabb(bounds._aabb)

func _init_mesh():
	prints(size, square_size)
	mesh_size = 256 if square_size <= 256 else 512 if square_size <= 512 else 1024
	mesh = load("res://addons/cartographer/meshes/clipmap_%s.obj" % mesh_size)
	

func _init_material():
	if material_override == null:
		material_override = ShaderMaterial.new()
		material_override.shader = shader
#		_update_material_params()

func _update_material_params():
	material_override.set_shader_param("terrain_textures", terrain_layers.textures)
	material_override.set_shader_param("use_triplanar", terrain_layers.use_triplanar)
	material_override.set_shader_param("uv1_scale", terrain_layers.uv1_scale)
	material_override.set_shader_param("terrain_size", size)
	material_override.set_shader_param("sq_dim", square_size)
	
	set_painter_texture(terrain_layers.masks)
	material_override.set_shader_param("terrain_masks", get_masks())
	material_override.set_shader_param("terrain_height", get_height_map())

func _init_terrain_layers():
	if terrain_layers == null:
		terrain_layers = CartoTerrainLayers.new()
		terrain_layers.connect("changed", self, "_update_material_params")

func _init_editing():
	if Engine.is_editor_hint():
		sculptor = find_node("Sculptor")
		painter = find_node("Painter")
		if not sculptor:
			sculptor = TexturePainter.new()
			sculptor.name = "Sculptor"
			add_child(sculptor)
		if not painter:
			painter = TexturePainter.new()
			painter.name = "Painter"
			add_child(painter)

func _init():
	bounds = CartoTerrainBounds.new(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	# A custom AABB is needed because vertices are offset by the GPU
	set_custom_aabb(bounds._aabb)

func _enter_tree():
	_init_mesh()
	_init_material()
	_init_terrain_layers()
	_init_editing()
	_update_material_params()

func set_height_map(m):
	height_map = m
	if sculptor:
		sculptor.texture = m

func get_height_map():
	prints("get_height_map", sculptor, height_map)
	return height_map if not sculptor else sculptor.get_texture()

func set_painter_texture(m):
	if painter:
		painter.texture = m

func get_masks():
	return terrain_layers.masks if not painter else painter.get_texture()

func can_edit():
	return sculptor and painter

func is_editable():
	return height_map and terrain_layers and terrain_layers.textures

func paint(action: int, pos: Vector2):
	if not (can_edit() and is_editable()):
		return ERR_UNAVAILABLE
	
	sculptor.brush = brush
	painter.brush = brush
	var on = action & Cartographer.Action.ON
	var just_changed = action & Cartographer.Action.JUST_CHANGED
	
	if not on and just_changed:
		var img = painter.get_texture().get_data()
		terrain_layers.masks.create_from_image(img)
	
	if action & (Cartographer.Action.RAISE | Cartographer.Action.LOWER):
		sculptor.paint_height(action, pos)
	elif action & (Cartographer.Action.PAINT | Cartographer.Action.ERASE | Cartographer.Action.FILL):
		painter.paint_masks(action, pos, terrain_layers.selected)

func intersect_ray(from: Vector3, dir: Vector3):
	var hmap = get_height_map()
	from = transform.xform_inv(from)
	return bounds.intersect_ray(from, dir, hmap)
