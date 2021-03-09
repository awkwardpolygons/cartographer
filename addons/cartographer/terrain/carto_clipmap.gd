tool
extends MultiMeshInstance
class_name CartoClipmap

enum Base {BASE_2 = 2, BASE_3 = 3}
export(float, 32, 10240, 32) var width: float = 256 setget set_width
export(float, 32, 10240, 32) var depth: float = 256 setget set_depth
export(float, 32, 10240, 32) var height: float = 64 setget set_height
export(Base) var base = Base.BASE_2 setget set_base
export(Material) var material: Material setget set_material
var size: Vector3 = Vector3(256, 64, 256) setget set_size
var diameter: float = max(size.x, size.z)
var mesh_diameter = 128
var center: MeshInstance
export(Mesh) var center_mesh: Mesh = preload("res://addons/cartographer/meshes/clipmap_center_quad.obj") setget set_center_mesh
var inst_mul = 2

func set_center_mesh(v):
	center.mesh = v

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
	material_override = material
	center.material_override = material

func _init():
	center = MeshInstance.new()
	add_child(center)
	
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	self.material = ShaderMaterial.new()
	self.material.shader = preload("res://addons/cartographer/terrain/carto_clipmap.shader")
	
	_load_meshes()
	_update_bounds()
	_update_transforms()

func _load_meshes():
#	center.mesh = load("res://addons/cartographer/meshes/better_clipmap_center_128_base_%s.obj" % base)
#	multimesh.mesh = load("res://addons/cartographer/meshes/better_clipmap_128_base_%s.obj" % base)
#	center.mesh = load("res://addons/cartographer/meshes/clipmap_center.obj")
	center.mesh = center_mesh
	multimesh.mesh = load("res://addons/cartographer/meshes/clipmap_ring_base%s_quad2.obj" % base)
	mesh_diameter = 256.0 if base == Base.BASE_3 else 128.0

func _update_bounds():
	diameter = max(size.x, size.z)
	var aabb = AABB(-Vector3(size.x/2.0, 0, size.z/2.0), size)
#	prints("-->", self.name, aabb.position, aabb.end)
	set_custom_aabb(aabb)
#	multimesh.mesh.custom_aabb = aabb
	
	center.set_custom_aabb(aabb)
	# Calculate the instance count based on the mesh size
	multimesh.instance_count = ceil(log(diameter / mesh_diameter) / log(base) + 1) * inst_mul
#	multimesh.instance_count = 2
	if material_override:
		material_override.set_shader_param("INSTANCE_COUNT", multimesh.instance_count)
		material_override.set_shader_param("clipmap_size", size)
		material_override.set_shader_param("clipmap_diameter", diameter)

func _update_transforms():
	var angle = 360.0 / inst_mul
	
	for idx in multimesh.instance_count:
		var lvl = float(int(idx) / inst_mul)
		var mul = pow(base, lvl)
		mul = mul if int(idx) % inst_mul == 0 else -mul
#		var rot = deg2rad(float(int(idx) % inst_mul) * angle)
		var mov = mesh_diameter
		var trn: Transform = Transform(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(0, 0, 0))
#		trn = trn.rotated(Vector3.UP, rot)
		trn = trn.scaled(Vector3(mul, 1, mul))
#		trn = trn.translated(Vector3(0, 0, mov))
		
		multimesh.set_instance_transform(idx, trn)

func _physics_process(delta):
	var cam = get_tree().root.get_camera()
	cam = cam if cam else Cartographer.editor_camera
	var loc = cam.get_camera_transform().origin
	var stride = 32.0
	loc = (loc / stride).floor() * stride
#	prints("-->", loc)
	loc.y = transform.origin.y
	transform.origin = loc
#	center.transform.origin.x = loc.x
#	center.transform.origin.z = loc.z
#	for idx in multimesh.instance_count:
#		var t = multimesh.get_instance_transform(idx)
##		prints(t.origin)
#		t.origin.x = loc.x
#		t.origin.z = loc.z
#		multimesh.set_instance_transform(idx, t)
		
