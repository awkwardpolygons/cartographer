tool
extends CartoClipmap
class_name CartoMegaTerrain

func set_clipmap_offset(v):
	.set_clipmap_offset(v)
#	var children = get_children()
#	for ch in children:
#		if ch is CartoMegaTexture:
#			ch.scroll(v)

func intersect_ray(from: Vector3, dir: Vector3, refresh: bool = true) -> Vector3:
	from = transform.xform_inv(from)
	var top = Plane(Vector3.UP, transform.origin.y + clipmap_size.y)
	var bottom = Plane(Vector3.UP, transform.origin.y)
	
	var a = top.intersects_ray(from, dir)
	a = a if a else from
	var b = bottom.intersects_ray(from, dir)
	b = b if b else (dir * 2000.0)
	
	if b.distance_squared_to(from) < a.distance_squared_to(from):
		var tmp = a
		a = b
		b = tmp
	
	return b
