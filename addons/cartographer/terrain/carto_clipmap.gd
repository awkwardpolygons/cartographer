tool
extends MultiMeshInstance
class_name CartoClipmap

export(float, 24, 4096, 24) var width: float = 256 setget set_width
export(float, 24, 4096, 24) var depth: float = 256 setget set_depth
export(float, 24, 4096, 24) var height: float = 64 setget set_height
export(Material) var material: Material setget set_material
var size: Vector3 = Vector3(256, 64, 256) setget set_size
var diameter: float = max(size.x, size.z)
var mesh_diameter = 0

signal size_changed

func set_width(w: float):
	width = w
	self.size = Vector3(w, size.y, size.z)

func set_depth(d: float):
	depth = d
	self.size = Vector3(size.x, size.y, d)

func set_height(h: float):
	height = h
	self.size = Vector3(size.x, h, size.z)

func set_size(s):
	size = s
	_update_bounds()
	_update_transforms()
	emit_signal("size_changed", size)

func set_material(v):
	material = v
	material_override.next_pass = material

func _init():
	material_override = ShaderMaterial.new()
	material_override.shader = preload("res://addons/cartographer/terrain/carto_clipmap.shader")
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = preload("res://addons/cartographer/meshes/better_clipmap_by_3.obj")
	mesh_diameter = 96.0
	_update_bounds()
	_update_transforms()

func _update_bounds():
	diameter = max(size.x, size.z)
	var aabb = AABB(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	set_custom_aabb(aabb)
	multimesh.mesh.custom_aabb = aabb
	# Calculate the instance count based on the mesh size,
	# plus one to correct the count, and plus one extra for clipping
	multimesh.instance_count = ceil(log(diameter / mesh_diameter) / log(3)) * 4 + 1
	if material_override:
		material_override.set_shader_param("INSTANCE_COUNT", multimesh.instance_count)
		material_override.set_shader_param("terrain_size", size)
		material_override.set_shader_param("terrain_diameter", diameter)

func _update_transforms():
	for idx in multimesh.instance_count:
#		prints(idx)
		idx -= 1;
		var lvl = float(int(idx) / 4);
		var mul = pow(3.0, lvl);
		var rot = deg2rad(float((0 if idx < 0 else int(idx)) % 4) * 90.0)
		var mov = 96.0 * float(0 if idx < 0 else 1)
#		prints(rot, mov, mul)
		var trn: Transform = Transform(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(0, 0, 0))
		trn = trn.rotated(Vector3.UP, rot)
		trn = trn.scaled(Vector3(mul, 1, mul))
		trn = trn.translated(Vector3(-mov, 0, mov))
#		prints(trn)
		multimesh.set_instance_transform(idx + 1, trn)
