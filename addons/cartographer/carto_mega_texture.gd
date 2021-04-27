tool
extends Viewport
class_name CartoMegaTexture

# Exported
var texture_store: String = ""
var texture_height: float = 1000
var texture_resolution: int = 2048
var texture_layers: CartoTerrainLayers
var lens_scale: float = 1.0 setget set_lens_scale, get_lens_scale
var lens_stride: float = 32.0
var lens_offset: Vector2 = Vector2(0, 0) setget scroll, get_lens_offset
var lens_tracking: bool = true setget set_lens_tracking, get_lens_tracking

# Not exported
var grid

func set_lens_scale(v: float):
	lens_scale = v
	scroll(lens_offset)

func get_lens_scale():
	return lens_scale

func get_lens_offset():
	return lens_offset

func set_lens_tracking(v):
	lens_tracking = v
	set_physics_process(v)

func get_lens_tracking():
	return lens_tracking

func _init():
	set_physics_process(false)
	texture_layers = CartoTerrainLayers.new()
	size = Vector2(texture_resolution, texture_resolution)
	transparent_bg = true
	render_target_v_flip = true
	keep_3d_linear = true
	global_canvas_transform = Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(texture_resolution/2, texture_resolution/2))

func _notification(what):
	if what == NOTIFICATION_PARENTED:
		var p = get_parent()
		texture_height = p.clipmap_size.y if p is CartoMegaTerrain else texture_height

func _physics_process(delta):
	var cam = get_tree().root.get_camera()
	cam = cam if cam else Cartographer.editor_camera
	var off3 = cam.get_camera_transform().origin
	off3 = (off3 / lens_stride).floor() * lens_stride
	var off2 = Vector2(off3.x, off3.z)
	
	if -off2 != canvas_transform.origin:
		scroll(off2)

func _ready():
	var s = Sprite.new()
	s.texture = load("res://icon.png")
	add_child(s)
	grid = get_node_or_null("Grid")
	if grid == null:
		grid = Grid.new()
		grid.name = "Grid"
		add_child(grid)
	if is_inside_tree():
		grid.set_owner(get_tree().get_edited_scene_root())

func intersect_ray(from: Vector3, dir: Vector3, refresh: bool = true) -> Vector3:
	var transform = get_parent().transform
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

func scroll(offset: Vector2):
	lens_offset = offset
	if not is_inside_tree():
		return
	
	canvas_transform = Transform2D(Vector2(lens_scale, 0), Vector2(0, lens_scale), -lens_offset * lens_scale)

# Property exports
func _get_property_list():
	var properties = []
	properties.append(_prop_group("MegaTexture", "texture_"))
	properties.append(_prop_info("texture_store", TYPE_STRING, PROPERTY_HINT_DIR))
	properties.append(_prop_info("texture_height", TYPE_REAL))
	properties.append(_prop_info("texture_resolution", TYPE_INT))
	properties.append(_prop_info("texture_layers", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "CartoTerrainLayers"))
	properties.append(_prop_group("MegaTextureLens", "lens_"))
	properties.append(_prop_info("lens_scale", TYPE_REAL))
	properties.append(_prop_info("lens_stride", TYPE_REAL))
	properties.append(_prop_info("lens_offset", TYPE_VECTOR2))
	properties.append(_prop_info("lens_tracking", TYPE_BOOL))
	
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
		for y in 2:
			for x in 2:
				add_tile(Vector2(x - 1 , y - 1))
	
	func _exit_tree():
		world_2d = null
		queue_free()

	func _make_tile():
		var c = Cell.new()
		c.set_world2d(world_2d)
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
	var vp: CellPainter
	var canvas_transform: Transform2D
	
	func set_world2d(v):
		world_2d = v
		vp.world_2d = v
	
	func set_offset(v):
		.set_offset(v)
		canvas_transform.origin = -v
		vp.set_local_transform(canvas_transform)
#		vp.canvas_transform = canvas_transform
		prints("set_offset:", vp.canvas_transform)
	
	func _init():
		centered = false
		canvas_transform = Transform2D()
		vp = CellPainter.new()
		vp.size = Vector2(resolution, resolution)
		vp.render_target_v_flip = true
		vp.render_target_update_mode = Viewport.UPDATE_ALWAYS
#		vp.global_canvas_transform.origin = Vector2(resolution/2, resolution/2)
		add_child(vp)
		texture = vp.get_texture()
	
	func _ready():
#		vp.canvas_transform = canvas_transform
		vp.set_local_transform(canvas_transform)
		prints("_ready:", vp.canvas_transform)
		if is_inside_tree():
			vp.set_owner(get_tree().get_edited_scene_root())
	
	func _exit_tree():
		vp.queue_free()
		queue_free()


class CellPainter extends Viewport:
	export var local_transform: Transform2D setget set_local_transform
	export var global_transform: Transform2D setget set_global_transform
	
	func set_local_transform(v):
		local_transform = v
		set_canvas_transform(v)
	
	func set_global_transform(v):
		global_transform = v
		set_global_transform(v)
	
	func _init():
		render_target_v_flip = true
