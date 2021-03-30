tool
extends Node2D
class_name CartoMegaLens

export(int) var tiers: int = 3 setget set_tiers
export(int) var tiers_radix: int = 2 setget set_tiers_radix
export(int) var lens_resolution: int = 2048 setget set_lens_resolution
export(float) var render_scale: float = 1.0 setget set_render_scale
export(Vector2) var offset: Vector2 = Vector2(0, 0) setget scroll

var world_2d: World2D
var root: Viewport

func set_tiers(v: int):
	tiers = v if v > 0 else 1
	update_lenses()
	scroll(offset)

func set_lens_resolution(v: int):
	lens_resolution = v
	update_lenses()
	scroll(offset)

func set_tiers_radix(v: int):
	tiers_radix = v
	scroll(offset)

func set_render_scale(v: float):
	render_scale = v
	scroll(offset)

func _init():
	world_2d = World2D.new()
	scroll(offset)

func _enter_tree():
#	world_2d = get_tree().root.world_2d
	update_lenses()
#	var cam = get_tree().root.get_camera()
#	cam.connect()

func _ready():
	scroll(offset)

#func _physics_process(delta):
#	var cam = get_tree().root.get_camera()
#	cam = cam if cam else Cartographer.editor_camera
#	var loc = cam.get_camera_transform().origin
##	prints("-->", loc)
#	var stride = 32.0
#	var off = Vector2(loc.x, loc.z)
#	off = (off / stride).floor() * stride
##	prints(off)
#	scroll(off)

func update_lenses():
	if not is_inside_tree():
		return
	
	var have = get_child_count()
	var want = tiers
	var children = get_children()
	
	for i in have:
		apply_lens_props(children[i], i)
	for i in range(have, want):
		add_lens()
	for i in range(want, have):
		remove_lens(children[i])
	
	root = get_lens(0)

func add_lens():
	var idx = get_child_count()
	var lens = Viewport.new()
	add_child(lens)
	apply_lens_props(lens, idx)

func remove_lens(lens: Node):
	remove_child(lens)
	lens.queue_free()

func get_lens(idx: int):
	return get_child(idx)

func apply_lens_props(lens: Viewport, idx: int):
	var global_offset = lens_resolution / 2
	lens.size = Vector2(lens_resolution, lens_resolution)
	lens.hdr = false
#	lens.render_target_update_mode = Viewport.UPDATE_ALWAYS
	lens.set_vflip(true)
	lens.world_2d = world_2d
	lens.global_canvas_transform = Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(global_offset, global_offset))
	
	if is_inside_tree():
		lens.set_owner(get_tree().get_edited_scene_root())
	return lens

func scroll(_offset: Vector2):
	offset = _offset
	if not is_inside_tree():
		return
	
	for i in get_child_count():
		var lens = get_child(i)
		var scale = 1.0/pow(tiers_radix, i) * render_scale
		lens.canvas_transform = Transform2D(Vector2(scale, 0), Vector2(0, scale), -offset * scale)
