tool
extends CSGMesh
class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

export(Vector3) var size: Vector3 = Vector3(20, 20, 20) setget _set_size
export(Array, Texture) var textures = [] setget _set_textures

var csg: CSGMesh = self
var painter: TexturePainter setget , _get_painter

var aabb: AABB
var bbox: Array setget , _get_bbox

var terrain_layers: TextureArray
var terrain_masks: ImageTexture


func _set_size(s: Vector3):
	size = s
	# Update the bbox with new size
	bbox = Geometry.build_box_planes(size/2)
	# Update the custom aabb when the size changes
	_update_custom_aabb()
	if csg.mesh:
		csg.mesh.size = Vector2(s.x, s.z)
	if csg.material:
		csg.material.set_shader_param("terrain_size", s)

func _get_bbox():
	if len(bbox) == 0:
		bbox = Geometry.build_box_planes(size/2)
	return bbox

func _get_painter():
	if not painter:
		painter = get_node("TexturePainter")
	return painter

func _set_textures(ta):
	print(ta)
	textures = ta

# A custom AABB is needed because vertices are offset by the GPU, so we set
# the custom AABB to `size`
func _update_custom_aabb():
	aabb = AABB(csg.transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	csg.set_custom_aabb(aabb)

func _init():
	terrain_masks = ImageTexture.new()
	terrain_masks.create(2048, 2048, false, Image.FORMAT_RGBA8)
	terrain_layers = TextureArray.new()

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
		csg.mesh.size = Vector2(size.x, size.z)

func init_material():
	if csg.material == null:
		print("ShaderMaterial.new()")
		csg.material = ShaderMaterial.new()

func init_painter():
#	print("TERRAIN CHILD COUNT: ", get_child_count())
	if not painter:
		print("TexturePainter.new()")
		painter = TexturePainter.new()
		painter.name = "TexturePainter"
		csg.add_child(painter)
	if csg.material:
#		csg.material.albedo_texture = painter.get_texture()
		csg.material.set_shader_param("terrain_size", size)
		csg.material.set_shader_param("texture", painter.get_texture())

func paint(action: int, pos: Vector2):
	if not painter:
		return
	painter.paint(action, pos)

func intersect_ray(from: Vector3, dir: Vector3):
	# Recenter the `from` vector based on the inverse of the terrains
	# transform, because intersections are based around the origin.
	from = self.transform.xform_inv(from)
	var pts = _bbox_intersect_ray(from, dir)
	
	if len(pts) >= 2:
		pts.sort_custom(self, "_sort_intersect_points")
	# If the camera (from vector) is inside the the bounding box then
	# we won't get two intersections, and must add `from` as the first point
	elif len(pts) == 1 and aabb.has_point(from):
		pts = [from, pts[0]]
	else:
		return null
	
	return _hmap_intersect_ray(pts[0], pts[-1], dir)

func _sort_intersect_points(a, b):
	return a.length_squared() > b.length_squared()

func _bbox_intersect_ray(from: Vector3, dir: Vector3, margin: float=0.04):
	from.y -= size.y/2
	var pts = []
	for plane in self.bbox:
		var pt = plane.intersects_ray(from, dir)
		if pt == null or abs(pt.x) > size.x/2 + margin or abs(pt.y) > size.y/2 + margin or abs(pt.z) > size.z/2 + margin:
			continue
		pt.y +=  size.y/2
		pts.append(pt)
	return pts

func _hmap_intersect_ray(from: Vector3, to: Vector3, dir: Vector3):
	var hm = painter.get_texture().get_data()
	var hm_size = hm.get_size()
	var pos = from
	for i in range(ceil((to - from).length())):
		pos += dir
		hm.lock()
		var x = (pos.x + size.x/2) / size.x * (hm_size.x - 1)
		x = clamp(x, 0, (hm_size.x - 1))
		var y = (pos.z + size.z/2) / size.z * (hm_size.y - 1)
		y = clamp(y, 0, (hm_size.y - 1))
		var pix = hm.get_pixel(x, y)
		hm.unlock()
		if pos.y <= pix.r * size.y:
#			pos -= dir
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
