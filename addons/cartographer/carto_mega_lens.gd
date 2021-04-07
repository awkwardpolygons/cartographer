tool
extends Node2D
class_name CartoMegaLens

# Exported with _get_property_list() 
var lens_resolution: int = 2048 setget set_lens_resolution
var lens_scale: float = 1.0 setget set_lens_scale
var lens_tiers: int = 3 setget set_lens_tiers
var lens_radix: int = 2 setget set_lens_radix
var lens_offset: Vector2 = Vector2(0, 0) setget scroll

var lens_world_2d: World2D
var lens_root: Viewport

func set_lens_tiers(v: int):
	lens_tiers = v if v > 0 else 1
	update_lenses()
	scroll(lens_offset)

func set_lens_resolution(v: int):
	lens_resolution = v
	update_lenses()
	scroll(lens_offset)

func set_lens_radix(v: int):
	lens_radix = v
	scroll(lens_offset)

func set_lens_scale(v: float):
	lens_scale = v
	scroll(lens_offset)

func _init():
	lens_world_2d = World2D.new()
	scroll(lens_offset)

func _enter_tree():
#	world_2d = get_tree().root.world_2d
	update_lenses()
#	var cam = get_tree().root.get_camera()
#	cam.connect()

func _ready():
	scroll(lens_offset)

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
	var want = lens_tiers
	var children = get_children()
	
	for i in have:
		apply_lens_props(children[i], i)
	for i in range(have, want):
		add_lens()
	for i in range(want, have):
		remove_lens(children[i])
	
	lens_root = get_lens(0)

func add_lens():
	var idx = get_child_count()
	var lens = Viewport.new()
	lens.name = "LensTier%s" % (idx + 1)
	lens.keep_3d_linear = true
	lens.hdr = true
	lens.usage = Viewport.USAGE_2D
	lens.render_target_v_flip = true
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
	lens.world_2d = lens_world_2d
	lens.global_canvas_transform = Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(global_offset, global_offset))
	
	if is_inside_tree():
		lens.set_owner(get_tree().get_edited_scene_root())
	return lens

func scroll(offset: Vector2):
	lens_offset = offset
	if not is_inside_tree():
		return
	
	for i in get_child_count():
		var lens = get_child(i)
		var scale = 1.0/pow(lens_radix, i) * lens_scale
		lens.canvas_transform = Transform2D(Vector2(scale, 0), Vector2(0, scale), -lens_offset * scale)

# Property exports
func _get_property_list():
	var properties = []
	properties.append(_prop_group("Lens", "lens_"))
	properties.append(_prop_info("lens_resolution", TYPE_INT))
	properties.append(_prop_info("lens_scale", TYPE_REAL))
	properties.append(_prop_info("lens_tiers", TYPE_INT, PROPERTY_HINT_RANGE, "1,6"))
	properties.append(_prop_info("lens_radix", TYPE_INT, PROPERTY_HINT_RANGE, "1,16"))
	properties.append(_prop_info("lens_offset", TYPE_VECTOR2))
	
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
