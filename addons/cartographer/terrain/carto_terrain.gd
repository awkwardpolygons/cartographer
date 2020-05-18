tool
extends CSGMesh
class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

export(Vector3) var size: Vector3 = Vector3(20, 20, 20) setget _set_size
export(Array, Texture) var textures = [] setget _set_textures

var terrain: CSGMesh = self
var painter: TexturePainter setget , _get_painter

var aabb: AABB
var bbox: Array setget , _get_bbox

var layers_size: Vector2 = Vector2(1024, 1024)
var masks_size: Vector2 = Vector2(1024, 1024)
export var terrain_layers: TextureArray = null
var terrain_masks: ImageTexture = null
var data_dir: Directory
const terrain_layers_filename = "terrain_layers.texarr"
export(Resource) var terrain_layers2

func _set_size(s: Vector3):
	size = s
	# Update the bbox with new size
	bbox = Geometry.build_box_planes(size/2)
	# Update the custom aabb when the size changes
	_update_custom_aabb()
	if terrain.mesh:
		terrain.mesh.size = Vector2(s.x, s.z)
	if terrain.material:
		terrain.material.set_shader_param("terrain_size", s)

func _get_bbox():
	if len(bbox) == 0:
		bbox = Geometry.build_box_planes(size/2)
	return bbox

func _get_painter():
	if not painter:
		if has_node("TexturePainter"):
			painter = get_node("TexturePainter")
	return painter

func _set_textures(ta):
	textures = ta
	if len(ta) > 0 && ta[-1] != null:
		_update_texture_layers()
	
# A custom AABB is needed because vertices are offset by the GPU, so we set
# the custom AABB to `size`
func _update_custom_aabb():
	aabb = AABB(terrain.transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	terrain.set_custom_aabb(aabb)

#func _init():
#	print('_init')

#func _notification(what):
#	print('_notification: ', what)
#	if what == 18:
#		terrain.material.set_shader_param("terrain_layers2", terrain_layers)

func _enter_tree():
	if not has_meta("uid"):
		# TODO: Improve this UID generator
		set_meta("uid", hash([OS.get_unique_id(), OS.get_unix_time(), randi()]) % 999999)
	
	_init_dir()
	terrain_layers2 = CartoTerrainLayers.new(data_dir.get_current_dir())
#	_init_terrrain_masks()
#	_init_terrain_layers()
#	_init_mesh()
#	_init_material()
#	if Engine.is_editor_hint():
#		_init_painter()

func _init_dir():
	var id = get_meta("uid")
	var data_part = "res://addons/cartographer/data/"
	var terrain_part = "terrain_%s/" % id
	var path = data_part + terrain_part
	data_dir = Directory.new()
	data_dir.open(data_part)
	if not data_dir.dir_exists(terrain_part):
		data_dir.make_dir(terrain_part)
	data_dir.open(path)

func _init_terrrain_masks():
	terrain_masks = ImageTexture.new()
	terrain_masks.create(masks_size.x * 2, masks_size.y * 2, false, Image.FORMAT_RGBA8)

func _init_terrain_layers():
	var path = data_dir.get_current_dir().plus_file(terrain_layers_filename)
	if data_dir.file_exists(terrain_layers_filename):
		terrain_layers = ResourceLoader.load(path)
	else:
		terrain_layers = TextureArray.new()
		terrain_layers.create(layers_size.x, layers_size.y, len(textures), Image.FORMAT_RGBA8)
	terrain_layers.take_over_path(path)

func _init_mesh():
	if terrain.mesh == null:
		print("PlaneMesh.new()")
		var mesh = PlaneMesh.new()
		mesh.size = Vector2(size.x, size.z)
		terrain.mesh = mesh

func _init_material():
	if terrain.material == null:
		print("ShaderMaterial.new()")
		terrain.material = ShaderMaterial.new()
		terrain.material.shader = load("res://addons/cartographer/terrain.shader")

func _init_painter():
#	print("TERRAIN CHILD COUNT: ", get_child_count())
	if not painter:
		print("TexturePainter.new()")
		painter = TexturePainter.new()
		painter.name = "TexturePainter"
		terrain.add_child(painter)
	if terrain.material:
#		terrain.material.albedo_texture = painter.get_texture()
		terrain.material.set_shader_param("terrain_size", size)
		terrain.material.set_shader_param("terrain_masks", painter.get_texture())

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

func _update_texture_layers():
#	terrain_layers = TextureArray.new()
	print("_update_texture_layers: ", terrain_layers)
	terrain_layers.create(layers_size.x, layers_size.y, len(textures), Image.FORMAT_RGBA8)
	
	for i in len(textures):
		var tex = textures[i]
		if tex == null:
			continue
		var img = tex.get_data()
		img.convert(Image.FORMAT_RGBA8)
		terrain_layers.set_layer_data(img, i)
	
	print("terrain_layers: ", terrain_layers, terrain_layers.get_depth())
	terrain.material.set_shader_param("terrain_layers", terrain_layers)
	
	if data_dir == null:
		print("data_dir: ", data_dir)
		# data_dir not yet initialized, skipping
		return
	var path = data_dir.get_current_dir().plus_file(terrain_layers_filename)
	save_texarr(terrain_layers, path)

func save_texarr(arr, path, compression=2):
	var file = File.new()
	if file.open(path, File.WRITE) != 0:
		push_error("Error opening %s file" % path)
		return
	
	file.store_8(ord('G'))
	file.store_8(ord('D'))
	file.store_8(ord('A')) # Godot ArrayTexture
	file.store_8(ord('T')) # Godot streamable texture
	
	file.store_32(arr.get_width())
	file.store_32(arr.get_height())
	file.store_32(arr.get_depth())
	file.store_32(arr.flags)
	file.store_32(arr.get_format())
	file.store_32(compression) # Compression: 0 - lossless (PNG), 1 - vram, 2 - uncompressed
	
	print("save_texarr: ", terrain_layers, terrain_layers.get_depth(), terrain_layers.data)
	for i in arr.get_depth():
		var img = arr.get_layer_data(i)
		print("save_texarr: ", img)
		img.clear_mipmaps()
		file.store_buffer(img.get_data())
	
	file.close()
