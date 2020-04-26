tool
extends CSGMesh
class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

export(Vector2) var size: Vector2 = Vector2(20, 20) setget _set_size
export(Texture) var height_map: Texture setget _set_height_map
export(Texture) var flow_map: Texture

var height_img: Image
var csg: CSGMesh = self
var texarr: TextureArray
var painter: TexturePainter setget ,_get_painter


func _set_size(s: Vector2):
	size = s
	if csg.mesh:
		csg.mesh.size = s

func _set_height_map(t: Texture):
	height_map = t

func _get_painter():
	return painter

func _enter_tree():
	init_mesh()
	init_material()
	if Engine.is_editor_hint():
		init_painter()

func init_mesh():
	if csg.mesh == null:
		print("PlaneMesh.new()")
		csg.mesh = PlaneMesh.new()
		csg.mesh.size = size

func init_material():
	if csg.material == null:
		csg.material = SpatialMaterial.new()

func init_painter():
	if not painter:
		painter = TexturePainter.new()
		csg.add_child(painter)
	if csg.material:
#		csg.material.albedo_texture = painter.get_texture()
		csg.material.set_shader_param("texture", painter.get_texture())

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
