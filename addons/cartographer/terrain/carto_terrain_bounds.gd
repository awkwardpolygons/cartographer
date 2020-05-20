tool
extends Object
class_name CartoTerrainBounds

var _aabb: AABB
var _bounds: Array
var position: Vector3 setget reposition, _get_position
var size: Vector3 setget resize, _get_size

func _init(position: Vector3, size: Vector3):
	_aabb = AABB(position, size)
	_bounds = Geometry.build_box_planes(size/2)

func _get_position():
	return _aabb.position

func _get_size():
	return _aabb.size

func reposition(position: Vector3):
	_aabb.position = position

func resize(size: Vector3):
	_aabb.size = size
	_bounds = Geometry.build_box_planes(size/2)

func reset(position: Vector3, size: Vector3):
	_aabb.position = position
	_aabb.size = size
	_bounds = Geometry.build_box_planes(size/2)

func encloses_aabb(aabb: AABB):
	return _aabb.encloses(aabb)

func encloses_point(point: Vector3):
	return _aabb.has_point(point)

func intersect_ray(from: Vector3, dir: Vector3, hmap: Texture = null):
	var pts = _bbox_intersect_ray(from, dir)
	
	if len(pts) >= 2:
		pts.sort_custom(self, "_sort_intersect_points")
	# If the camera (from vector) is inside the the bounding box then
	# we won't get two intersections, and must add `from` as the first point
	elif len(pts) == 1 and _aabb.has_point(from):
		pts = [from, pts[0]]
	else:
		return null
	
	return _hmap_intersect_ray(pts[0], pts[-1], dir, hmap)

func _sort_intersect_points(a, b):
	return a.length_squared() > b.length_squared()

func _bbox_intersect_ray(from: Vector3, dir: Vector3, margin: float=0.04):
	var size = self.size
	from.y -= size.y/2
	var pts = []
	for plane in _bounds:
		var pt = plane.intersects_ray(from, dir)
		if pt == null or abs(pt.x) > size.x/2 + margin or abs(pt.y) > size.y/2 + margin or abs(pt.z) > size.z/2 + margin:
			continue
		pt.y +=  size.y/2
		pts.append(pt)
	return pts

func _hmap_intersect_ray(from: Vector3, to: Vector3, dir: Vector3, hmap: Texture):
	var size = self.size
	var hm = hmap.get_data()
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
