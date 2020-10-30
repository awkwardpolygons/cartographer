tool
extends MultiMeshInstance
class_name CartoClipmap

enum Base {BASE_2 = 2, BASE_3 = 3}
export(float, 32, 4096, 32) var width: float = 256 setget set_width
export(float, 32, 4096, 32) var depth: float = 256 setget set_depth
export(float, 32, 4096, 32) var height: float = 64 setget set_height
export(Base) var base = Base.BASE_3 setget set_base
export(Material) var material: Material setget set_material
var size: Vector3 = Vector3(256, 64, 256) setget set_size
var diameter: float = max(size.x, size.z)
var mesh_diameter = 0
var center: MeshInstance

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

func set_base(v):
	base = v
	_load_meshes()
	_update_bounds()
	_update_transforms()

func set_material(v):
	material = v
	material_override.next_pass = material

func _init():
	material_override = ShaderMaterial.new()
	material_override.shader = preload("res://addons/cartographer/terrain/carto_clipmap.shader")
	
	center = MeshInstance.new()
#	center.mesh = preload("res://addons/cartographer/meshes/better_clipmap_center_128_base_3.obj")
	center.material_override = material_override
	add_child(center)
	
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
#	multimesh.mesh = load("res://addons/cartographer/meshes/better_clipmap_128_base_%s.obj" % base)
	
#	mesh_diameter = 128.0
	_load_meshes()
	_update_bounds()
	_update_transforms()

func _load_meshes():
	center.mesh = load("res://addons/cartographer/meshes/better_clipmap_center_128_base_%s.obj" % base)
	multimesh.mesh = load("res://addons/cartographer/meshes/better_clipmap_128_base_%s.obj" % base)
	mesh_diameter = 128.0

func _update_bounds():
	diameter = max(size.x, size.z)
	var aabb = AABB(transform.origin - Vector3(size.x/2.0, 0, size.z/2.0), size)
	prints(aabb)
	set_custom_aabb(aabb)
#	multimesh.mesh.custom_aabb = aabb
	
	center.set_custom_aabb(aabb)
	# Calculate the instance count based on the mesh size
	multimesh.instance_count = ceil(log(diameter / mesh_diameter) / log(base) + 0) * 4
#	multimesh.instance_count = 2
	if material_override:
		material_override.set_shader_param("INSTANCE_COUNT", multimesh.instance_count)
		material_override.set_shader_param("terrain_size", size)
		material_override.set_shader_param("terrain_diameter", diameter)

func _update_transforms():
	for idx in multimesh.instance_count:
		var lvl = float(int(idx) / 4);
		var mul = pow(base, lvl);
		var rot = deg2rad(float(int(idx) % 4) * 90.0)
		var mov = mesh_diameter
		var trn: Transform = Transform(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(0, 0, 0))
		trn = trn.rotated(Vector3.UP, rot)
		trn = trn.scaled(Vector3(mul, 1, mul))
		trn = trn.translated(Vector3(0, 0, mov))
		multimesh.set_instance_transform(idx, trn)
