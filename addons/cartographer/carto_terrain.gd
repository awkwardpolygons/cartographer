tool
extends CSGMesh
class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

export(Vector3) var size: Vector3 = Vector3(20, 20, 20) setget _set_size
export(Texture) var height_map: Texture setget _set_height_map
export(Texture) var flow_map: Texture

var bbox: Array setget , _get_bbox
var height_img: Image
var csg: CSGMesh = self
var texarr: TextureArray
var painter: TexturePainter setget , _get_painter


func _set_size(s: Vector3):
	size = s
	bbox = Geometry.build_box_planes(size/2)
	if csg.mesh:
		csg.mesh.size = Vector2(s.x, s.z)

func _get_bbox():
	if len(bbox) == 0:
		bbox = Geometry.build_box_planes(size/2)
	return bbox

func _set_height_map(t: Texture):
	height_map = t

func _get_painter():
	if not painter:
		painter = get_node("TexturePainter")
	return painter

func _init():
	print("Terrain _init", get_children())

func _enter_tree():
	init_mesh()
	init_material()
	if Engine.is_editor_hint():
		init_painter()

#func _exit_tree():
#	if painter:
#		painter.queue_free()

func init_mesh():
	if csg.mesh == null:
		print("PlaneMesh.new()")
		csg.mesh = PlaneMesh.new()
		csg.mesh.size = size

func init_material():
	if csg.material == null:
		print("SpatialMaterial.new()")
		csg.material = SpatialMaterial.new()

func init_painter():
	print("TERRAIN CHILD COUNT: ", get_child_count())
	if not painter:
		print("TexturePainter.new()")
		painter = TexturePainter.new()
		painter.name = "TexturePainter"
		csg.add_child(painter)
	if csg.material:
#		csg.material.albedo_texture = painter.get_texture()
		csg.material.set_shader_param("texture", painter.get_texture())

func intersect_ray(from: Vector3, dir: Vector3):
	var pts = _bbox_intersect_ray(from, dir)
	if len(pts) < 2:
		return null
	
	var a = pts[0]
	var b = pts[1]
	pts = [a, b] if (from - a).length_squared() < (from - b).length_squared() else [b, a]
	return _hmap_intersect_ray(pts[0], pts[1], dir)

func _bbox_intersect_ray(from: Vector3, dir: Vector3):
	var pts = []
	for plane in self.bbox:
		var pt = plane.intersects_ray(from, dir)
		if pt == null or abs(pt.x) > 10 or abs(pt.y) > 10 or abs(pt.z) > 10:
			continue
		pts.append(pt)
	return pts

func _hmap_intersect_ray(from: Vector3, to: Vector3, dir: Vector3):
	var hm = painter.get_texture().get_data()
	var pos = from
	for i in range(ceil((to - from).length())):
		pos += dir
		hm.lock()
		var loc = (Vector2(pos.x + 10, pos.z + 10) / 20) * 512
		var pix = hm.get_pixel(loc.x, loc.y)
		hm.unlock()
		if pos.y <= pix.r * 8:
#			pos -= dir
			print("POS: ", pos)
			return pos
	return null

#func update_layer_data():
#	var layers = get_children()
#	if texarr == null:
#		texarr = TextureArray.new()
#	texarr.create(512, 512, get_child_count(), Image.FORMAT_DXT5)
#
#	for i in range(len(layers)):
#		var tex = layers[i].material.get_texture(SpatialMaterial.TEXTURE_ALBEDO)
#		var img = tex.get_data()
#		print(img.get_format(), Image.FORMAT_DXT5)
#		texarr.set_layer_data(img, i)
#
#	csg.material.set_shader_param("layers", texarr)
