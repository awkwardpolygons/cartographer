tool
extends CSGMesh
class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

export(Vector2) var size: Vector2 = Vector2(20, 20) setget set_size
const isCartoTerrain: bool = true
var csg: CSGMesh = self
var texarr: TextureArray

func set_size(s: Vector2):
	size = s
	csg.mesh.size = s

func _enter_tree():
	#if csg == null:
	#	csg = CSGMesh.new()
	#	add_child(csg)
	if csg.mesh == null:
		csg.mesh = PlaneMesh.new()
		csg.mesh.size = size
	
func _ready():
	#var this = CartoTerrain           # reference to the script
	print(csg.mesh)

func update_layer_data():
	var layers = get_children()
	if texarr == null:
		texarr = TextureArray.new()
	texarr.create(512, 512, get_child_count(), Image.FORMAT_DXT5)

	for i in range(len(layers)):
		var tex = layers[i].material.get_texture(SpatialMaterial.TEXTURE_ALBEDO)
		var img = tex.get_data()
		print(img.get_format(), Image.FORMAT_DXT5)
		texarr.set_layer_data(img, i)
	
	csg.material.set_shader_param("layers", texarr)
