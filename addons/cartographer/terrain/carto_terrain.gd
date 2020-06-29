tool
extends MultiMeshInstance
class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

export(float, 32, 1024, 32) var width: float = 256 setget _set_width
export(float, 32, 1024, 32) var depth: float = 256 setget _set_depth
export(float, 32, 1024, 32) var height: float = 64 setget _set_height
export(ShaderMaterial) var material setget _set_material
var size: Vector3 = Vector3(256, 64, 256) setget _set_size
var diameter: float = max(size.x, size.z)
var mesh_diameter = 0
var bounds: CartoTerrainBounds
var brush: PaintBrush setget _set_brush

signal size_changed

func _set_width(w: float):
	width = w
	self.size = Vector3(w, size.y, size.z)

func _set_depth(d: float):
	depth = d
	self.size = Vector3(size.x, size.y, d)

func _set_height(h: float):
	height = h
	self.size = Vector3(size.x, h, size.z)

func _set_material(m):
	material = m
	material_override = m

func _set_size(s):
	size = s
	diameter = max(size.x, size.z)
	_update_bounds()
	if material:
		material.set_shader_param("terrain_size", size)
		material.set_shader_param("terrain_diameter", diameter)
	emit_signal("size_changed", size)

func _set_brush(br: PaintBrush):
	brush = br
	if material:
		material.sculptor.brush = brush
		material.painter.brush = brush
		material.set_shader_param("brush_scale", brush.get_relative_brush_scale(2048))

func _update_bounds():
#	var aabb = AABB(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	bounds.reset(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	var aabb = bounds._aabb
	set_custom_aabb(aabb)
	multimesh.mesh.custom_aabb = aabb
	# Calculate the instance count based on the mesh size,
	# plus one to correct the count, and plus one extra for clipping
	multimesh.instance_count = ceil(log(diameter / mesh_diameter) / log(2)) + 1 + 1
	if material:
		material.set_shader_param("INSTANCE_COUNT", multimesh.instance_count)

func _init():
	multimesh = MultiMesh.new()
	multimesh.mesh = preload("res://addons/cartographer/meshes/clipmap_multi.obj")
	mesh_diameter = multimesh.mesh.get_aabb().get_longest_axis_size()
	bounds = CartoTerrainBounds.new(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	_update_bounds()

func _enter_tree():
	if not material:
		_set_material(CartoTerrainMaterial.new())
		material.set_shader_param("terrain_size", size)
		material.set_shader_param("terrain_diameter", diameter)
		material.set_shader_param("INSTANCE_COUNT", multimesh.instance_count)
	_init_editing()

func _exit_tree():
	if Engine.is_editor_hint():
		Cartographer.disconnect("active_brush_changed", self, "_set_brush")

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
		Cartographer.connect("active_brush_changed", self, "_set_brush")
		_set_brush(Cartographer.active_brush)

func can_edit():
	return material and material.sculptor and material.painter

func paint(action: int, pos: Vector2):
	if not can_edit():
		return ERR_UNAVAILABLE
	
	material.set_shader_param("brush_pos", pos)
	
	var sculptor = material.sculptor
	var painter = material.painter
	var on = action & Cartographer.Action.ON
	var just_changed = action & Cartographer.Action.JUST_CHANGED
	
	if action & (Cartographer.Action.RAISE | Cartographer.Action.LOWER):
		sculptor.paint_height(action, pos)
		if not on and just_changed:
			material.commit_sculptor()
	elif action & (Cartographer.Action.PAINT | Cartographer.Action.ERASE | Cartographer.Action.FILL):
		painter.paint_masks(action, pos, material.selected)
		if not on and just_changed:
			material.commit_painter()

func intersect_ray(from: Vector3, dir: Vector3):
	var hmap = material.get_height_map()
	from = transform.xform_inv(from)
	return bounds.intersect_ray(from, dir, hmap)
