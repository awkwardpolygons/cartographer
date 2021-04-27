tool
extends Spatial
class_name CartoClipmap

# Exported
var layers: int = 1 setget set_layer_mask, get_layer_mask
var material: Material setget set_material
var clipmap_size: Vector3 = Vector3(2048, 1024, 2048) setget set_clipmap_size
var clipmap_stride: float = 32.0
var clipmap_offset: Vector2 setget set_clipmap_offset
var clipmap_tracking: bool = true setget set_clipmap_tracking

# Not exported
var center_mesh: Mesh
var center_mesh_inst: MeshInstance
var ring_mesh: Mesh
var ring_mesh_inst: MultiMeshInstance
var ring_parts: int = 2
var ring_base: int = 2
var ring_count
var diameter
var center_diameter
var rings_diameter

func set_layer_mask(v):
	layers = v
	if center_mesh_inst:
		center_mesh_inst.layers = layers
	if ring_mesh_inst:
		ring_mesh_inst.layers = layers

func get_layer_mask():
	return layers

func set_layer_mask_bit(layer: int, enabled: bool):
	var b = 1 << layer
	var v = layers | b if enabled else layers & ~b
	set_layer_mask(v)

func get_layer_mask_bit(layer: int):
	return layers & (1 << layer)

func set_clipmap_size(v: Vector3):
	clipmap_size = v
	_update_bounds()
	_update_transforms()

func set_clipmap_offset(v):
	clipmap_offset = v
	var off: Vector3 = Vector3(v.x, 0.0, v.y)
	center_mesh_inst.transform.origin = off
	ring_mesh_inst.transform.origin = off
	if material:
		material.set_shader_param("origin", off)

func set_clipmap_tracking(v):
	clipmap_tracking = v
	set_physics_process(v)

func set_material(v: Material):
	material = v
	center_mesh_inst.material_override = v
	ring_mesh_inst.material_override = v

func _init():
	center_mesh = preload("res://addons/cartographer/meshes/clipmap_center_quad.obj")
	center_mesh_inst = MeshInstance.new()
	center_mesh_inst.mesh = center_mesh
	ring_mesh = preload("res://addons/cartographer/meshes/clipmap_ring_base2_quad2.obj")
	ring_mesh_inst = MultiMeshInstance.new()
	ring_mesh_inst.multimesh = MultiMesh.new()
	ring_mesh_inst.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	ring_mesh_inst.multimesh.mesh = ring_mesh
	self.add_child(center_mesh_inst)
	self.add_child(ring_mesh_inst)
	set_physics_process(clipmap_tracking)

func _physics_process(delta):
	_update_offset()

func _ready():
	set_clipmap_size(clipmap_size)

func _update_bounds():
	var center_size = center_mesh.get_aabb().size
	center_diameter = max(center_size.x, center_size.z)
	diameter = max(clipmap_size.x, clipmap_size.z)
	ring_count = ceil(log(diameter / center_diameter) / log(ring_base))
	rings_diameter = pow(ring_base, ring_count) * center_diameter
	ring_mesh_inst.multimesh.instance_count = ring_count * ring_parts
	
	var center_aabb = center_mesh.get_aabb()
	center_aabb.size.y = clipmap_size.y
	center_mesh.set_custom_aabb(center_aabb)
	var ring_aabb = AABB(-Vector3(rings_diameter/2.0, 0, rings_diameter/2.0), Vector3(rings_diameter, clipmap_size.y, rings_diameter))
	ring_mesh_inst.set_custom_aabb(ring_aabb)

func _update_transforms():
	for idx in ring_mesh_inst.multimesh.instance_count:
		var lvl = float(int(idx) / ring_parts)
		var mul = pow(ring_base, lvl)
		mul = mul if int(idx) % ring_parts == 0 else -mul
		var trn: Transform = Transform(Vector3(mul, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, mul), Vector3(0, 0, 0))
		ring_mesh_inst.multimesh.set_instance_transform(idx, trn)

func _update_offset():
	var cam = get_tree().root.get_camera()
	cam = cam if cam else Cartographer.editor_camera
	var off3 = cam.get_camera_transform().origin
	off3 = (off3 / clipmap_stride).floor() * clipmap_stride
	var off2 = Vector2(off3.x, off3.z)
	if off2 != clipmap_offset:
		set_clipmap_offset(off2)

func get_aabb():
	return ring_mesh_inst.get_aabb()

# Property exports
func _get_property_list():
	var properties = []
	properties.append(_prop_info("layers", TYPE_INT, PROPERTY_HINT_LAYERS_3D_RENDER))
	properties.append(_prop_info("material", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "SpatialMaterial,ShaderMaterial"))
	properties.append(_prop_group("Clipmap", "clipmap_"))
	properties.append(_prop_info("clipmap_size", TYPE_VECTOR3))
	properties.append(_prop_info("clipmap_stride", TYPE_INT))
	properties.append(_prop_info("clipmap_offset", TYPE_VECTOR2))
	properties.append(_prop_info("clipmap_tracking", TYPE_BOOL))
	
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
