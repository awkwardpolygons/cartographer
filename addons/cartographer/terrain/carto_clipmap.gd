tool
extends MultiMeshInstance
class_name CartoClipmap

export(float, 32, 1024, 32) var width: float = 256 setget set_width
export(float, 32, 1024, 32) var depth: float = 256 setget set_depth
export(float, 32, 1024, 32) var height: float = 64 setget set_height
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
	emit_signal("size_changed", size)

func set_material(v):
	material = v
	material_override.next_pass = material

func _init():
	material_override = ShaderMaterial.new()
	material_override.shader = preload("res://addons/cartographer/terrain/carto_clipmap.shader")
	multimesh = MultiMesh.new()
	multimesh.mesh = preload("res://addons/cartographer/meshes/better_clipmap.obj")
	mesh_diameter = multimesh.mesh.get_aabb().get_longest_axis_size()
	_update_bounds()

func _update_bounds():
	diameter = max(size.x, size.z)
	var aabb = AABB(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	set_custom_aabb(aabb)
	multimesh.mesh.custom_aabb = aabb
	# Calculate the instance count based on the mesh size,
	# plus one to correct the count, and plus one extra for clipping
	multimesh.instance_count = ceil(log(diameter / mesh_diameter) / log(2)) + 1 + 1
	if material:
		material.set_shader_param("INSTANCE_COUNT", multimesh.instance_count)
		material.set_shader_param("terrain_size", size)
		material.set_shader_param("terrain_diameter", diameter)
