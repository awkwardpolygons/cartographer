tool
extends CollisionShape
class_name CollisionCartoTerrain

export(NodePath) var terrain_path: NodePath setget _set_terrain_path
var _terrain: CartoTerrain

func _set_terrain_path(p):
	terrain_path = p
	_update_terrain()

func _update_terrain():
	_ignore()
	if is_inside_tree():
		var node = get_node(terrain_path)
		if node is CartoTerrain:
			_terrain = node
			_bind_terrain_props()
			_watch()
		else:
			_terrain = null

func _bind_terrain_props():
	if not (_terrain and shape is HeightMapShape):
		return
	
	var w = _terrain.width
	var d = _terrain.depth
	var h = _terrain.height
	var e = _terrain.square_size
	var hmap = _terrain.material.height_map.get_data() if _terrain.material and _terrain.material.height_map else null
	
	shape.map_width = w
	shape.map_depth = d
	
	if hmap:
		hmap.resize(e, e, Image.INTERPOLATE_LANCZOS)
		_center_crop(hmap, Vector2(shape.map_width, shape.map_depth))
		_bind_height_data(hmap, h)

func _bind_height_data(img: Image, height_mul):
	img.lock()
	var i = 0
	var data = shape.map_data
	for y in img.get_height():
		for x in img.get_width():
			var px = img.get_pixel(x, y)
			var h =(px.r * 256.0 + px.g) / (256.0)
			data[i] = h * height_mul
			i += 1
	img.unlock()
	shape.map_data = data

func _init():
	shape = HeightMapShape.new()
	scale = Vector3(1.0, 1.0, 1.0)

func _enter_tree():
	_update_terrain()

func _exit_tree():
	_ignore()

func _watch():
	_terrain.material.connect("changed", self, "_bind_terrain_props")

func _ignore():
	if _terrain:
		_terrain.material.disconnect("changed", self, "_bind_terrain_props")

func _center_crop(img: Image, crop: Vector2):
	var size = img.get_size()
	var diff = size - crop
	
	img.crop(size.x - diff.x / 2, size.y - diff.y / 2)
	img.flip_x()
	img.flip_y()
	size = img.get_size()
	img.crop(size.x - diff.x / 2, size.y - diff.y / 2)
	img.flip_y()
	img.flip_x()
