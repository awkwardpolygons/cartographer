tool
extends Spatial
class_name CartoMegaTexture

var texture_height: float = 1000
var texture_layers: CartoTerrainLayers

var mega_lens: CartoMegaLens
var grid

func _init():
	texture_layers = CartoTerrainLayers.new()

func _notification(what):
	if what == NOTIFICATION_PARENTED:
		var p = get_parent()
		texture_height = p.clipmap_size.y if p is CartoMegaTerrain else texture_height

func _ready():
	mega_lens = get_node_or_null("MegaLens")
	if mega_lens == null:
		mega_lens = CartoMegaLens.new()
		mega_lens.lens_tiers = 1
		mega_lens.name = "MegaLens"
		add_child(mega_lens)
	if is_inside_tree():
		mega_lens.set_owner(get_tree().get_edited_scene_root())
	grid = mega_lens.get_child(0).get_node_or_null("Grid")
	if grid == null:
		grid = Grid.new()
		grid.name = "Grid"
		mega_lens.get_child(0).add_child(grid)
	if is_inside_tree():
		grid.set_owner(get_tree().get_edited_scene_root())

func intersect_ray(from: Vector3, dir: Vector3, refresh: bool = true) -> Vector3:
	from = transform.xform_inv(from)
	var top = Plane(Vector3.UP, transform.origin.y + texture_height)
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

func add_brush_stroke():
	var bs = CartoBrushStroke.new()
	grid.get_child(0).get_child(0).add_child(bs)
	if is_inside_tree():
		bs.set_owner(get_tree().get_edited_scene_root())
	return bs

# Property exports
func _get_property_list():
	var properties = []
	properties.append(_prop_group("MegaTexture", "texture_"))
	properties.append(_prop_info("texture_height", TYPE_REAL))
	properties.append(_prop_info("texture_layers", TYPE_OBJECT))
	
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


class Grid extends Node2D:
	const tile_size: int = 2048
	export(int) var size: int = 16384
	export(int) var tile_resolution: int = 2048
	var tiles = {}
	var world_2d: World2D

	func _init():
		world_2d = World2D.new()

	func _ready():
		for y in 4:
			for x in 4:
				add_tile(Vector2(x - 2 , y - 2))

	func _make_tile():
		var c = Cell.new()
		c.world_2d = world_2d
		if is_inside_tree():
			c.set_owner(get_tree().get_edited_scene_root())
		return c

	func add_tile(pos: Vector2):
		var tile = _make_tile()
		tile.set_meta("tile_pos", pos)
		tiles[pos] = tile
		
#		tile.texture = preload("res://example/assets/textures/realistic/cc0textures/Gravel011_2K-JPG/Gravel011_2K_Color.jpg")
		tile.name = "Cell_%s_%s" % [pos.x, pos.y]
		add_child(tile)
		tile.set_offset(tile_size * pos)
		if is_inside_tree():
			tile.set_owner(get_tree().get_edited_scene_root())

	func get_tile(pos: Vector2):
		return tiles.get(pos)

	func remove_tile(pos: Vector2):
		var tile: Sprite = tiles.get(pos)
		if tile:
			remove_child(tile)
			tile.queue_free()

class Cell extends Sprite:
	var resolution: int = 2048
	var world_2d: World2D setget set_world2d
	var vp: Viewport
	var canvas_transform: Transform2D
	
	func set_world2d(v):
		world_2d = v
		vp.world_2d = v
	
	func set_offset(v):
		.set_offset(v)
		canvas_transform.origin = v
		vp.canvas_transform = canvas_transform
	
	func _init():
		canvas_transform = Transform2D()
		vp = Viewport.new()
		vp.size = Vector2(resolution, resolution)
		vp.render_target_v_flip = true
		vp.global_canvas_transform.origin = Vector2(resolution/2, resolution/2)
		add_child(vp)
		texture = vp.get_texture()
	
	func _ready():
		vp.canvas_transform = canvas_transform
		if is_inside_tree():
			vp.set_owner(get_tree().get_edited_scene_root())
	
	func _exit_tree():
		vp.queue_free()
		queue_free()
