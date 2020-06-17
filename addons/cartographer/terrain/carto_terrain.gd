tool
extends MeshInstance
class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

export(float, 32, 1024, 32) var width: float = 256 setget _set_width
export(float, 32, 1024, 32) var depth: float = 256 setget _set_depth
export(float, 32, 1024, 32) var height: float = 64 setget _set_height
export(ShaderMaterial) var material setget _set_material
var size: Vector3 = Vector3(256, 64, 256) setget _set_size
var mesh_size: float
var square_size: float = max(size.x, size.z)
var bounds: CartoTerrainBounds
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
	size = s
	_update_bounds()
	square_size = max(size.x, size.z)
	var ms = 256 if square_size <= 256 else 512 if square_size <= 512 else 1024
	if mesh == null or ms != mesh_size:
		_init_mesh()
	if material:
		material.set_shader_param("terrain_size", size)
		material.set_shader_param("sq_dim", square_size)

func _set_material(m):
	material = m
	material_override = m

func _update_bounds():
	bounds.reset(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	# A custom AABB is needed because vertices are offset by the GPU
	set_custom_aabb(bounds._aabb)

func _init_mesh():
	mesh_size = 256 if square_size <= 256 else 512 if square_size <= 512 else 1024
	mesh = load("res://addons/cartographer/meshes/clipmap_%s.obj" % mesh_size)

func _init_editing():
	if Engine.is_editor_hint():
		var sculptor = find_node("Sculptor")
		var painter = find_node("Painter")
		if not sculptor:
			add_child(material.sculptor)
		else:
			material.sculptor = sculptor
		if not painter:
			add_child(material.painter)
		else:
			material.painter = painter

func _init():
	bounds = CartoTerrainBounds.new(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	# A custom AABB is needed because vertices are offset by the GPU
	set_custom_aabb(bounds._aabb)

func _enter_tree():
	if not material:
		_set_material(CartoTerrainMaterial.new())
		material.set_shader_param("terrain_size", size)
		material.set_shader_param("sq_dim", square_size)
	_init_mesh()
	_init_editing()

func can_edit():
	return material and material.sculptor and material.painter

func paint(action: int, pos: Vector2):
	if not can_edit():
		return ERR_UNAVAILABLE
	
	var sculptor = material.sculptor
	var painter = material.painter
	sculptor.brush = brush
	painter.brush = brush
	var on = action & Cartographer.Action.ON
	var just_changed = action & Cartographer.Action.JUST_CHANGED
	
	if not on and just_changed:
		material.commit_painter()
		material.commit_sculptor()
	
	if action & (Cartographer.Action.RAISE | Cartographer.Action.LOWER):
		sculptor.paint_height(action, pos)
	elif action & (Cartographer.Action.PAINT | Cartographer.Action.ERASE | Cartographer.Action.FILL):
		painter.paint_masks(action, pos, material.selected)

func intersect_ray(from: Vector3, dir: Vector3):
	var hmap = material.get_height_map()
	from = transform.xform_inv(from)
	return bounds.intersect_ray(from, dir, hmap)
