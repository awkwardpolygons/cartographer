tool
extends MultiMeshInstance
class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

export(float, 32, 1024, 32) var width: float = 256 setget _set_width
export(float, 32, 1024, 32) var depth: float = 256 setget _set_depth
export(float, 32, 1024, 32) var height: float = 64 setget _set_height
export(ShaderMaterial) var material setget _set_material
var size: Vector3 = Vector3(256, 64, 256) setget _set_size
var diameter: float = max(size.x, size.z)
var mesh_diameter = 0
var brush: PaintBrush setget _set_brush
var _aabb: AABB

signal size_changed

func _set_width(w: float):
	width = w
	self.size = Vector3(w, size.y, size.z)

func _set_depth(d: float):
	depth = d
	self.size = Vector3(size.x, size.y, d)

func _set_height(h: float):
	height = h
	self.size = Vector3(size.x, h, size.z)

func _set_material(m):
	material = m
	material_override = m

func _set_size(s):
	size = s
	_update_bounds()
	emit_signal("size_changed", size)

func _set_brush(br: PaintBrush):
	brush = br
	if material:
		material.sculptor.brush = brush
		material.painter.brush = brush
		if brush:
			material.set_shader_param("brush_scale", brush.get_relative_brush_scale(2048))

func _update_bounds():
	diameter = max(size.x, size.z)
	_aabb = AABB(transform.origin - Vector3(size.x/2, 0, size.z/2), size)
	set_custom_aabb(_aabb)
	multimesh.mesh.custom_aabb = _aabb
	# Calculate the instance count based on the mesh size,
	# plus one to correct the count, and plus one extra for clipping
	multimesh.instance_count = ceil(log(diameter / mesh_diameter) / log(2)) + 1 + 1
	if material:
		material.set_shader_param("INSTANCE_COUNT", multimesh.instance_count)
		material.set_shader_param("terrain_size", size)
		material.set_shader_param("terrain_diameter", diameter)

func _init():
	multimesh = MultiMesh.new()
	multimesh.mesh = preload("res://addons/cartographer/meshes/clipmap_multi.obj")
	mesh_diameter = multimesh.mesh.get_aabb().get_longest_axis_size()
	_update_bounds()

func _enter_tree():
	if not material:
		_set_material(CartoTerrainMaterial.new())
		material.set_shader_param("terrain_size", size)
		material.set_shader_param("terrain_diameter", diameter)
		material.set_shader_param("INSTANCE_COUNT", multimesh.instance_count)
	_init_editing()

func _exit_tree():
	if Engine.is_editor_hint():
		Cartographer.disconnect("active_brush_changed", self, "_set_brush")
		hmfetcher._exit()

func _init_editing():
	if Engine.is_editor_hint():
		var sculptor = find_node("Sculptor")
		var painter = find_node("Painter")
		if not sculptor:
			add_child(material.sculptor)
		else:
			material.sculptor = sculptor
		if not painter:
			add_child(material.painter)
		else:
			material.painter = painter
		Cartographer.connect("active_brush_changed", self, "_set_brush")
		_set_brush(Cartographer.active_brush)
		hmfetcher = HeightmapFetcher.new(material.get_height_map())

func can_edit():
	return material and material.sculptor and material.painter

func paint(action: int, pos: Vector2):
	if not can_edit():
		return ERR_UNAVAILABLE
	
	material.set_shader_param("brush_pos", pos)
	
	var sculptor = material.sculptor
	var painter = material.painter
	var on = action & Cartographer.Action.ON
	var just_changed = action & Cartographer.Action.JUST_CHANGED
	
	if action & (Cartographer.Action.RAISE | Cartographer.Action.LOWER):
		sculptor.paint_height(action, pos)
		# Use force_draw here and below to force Godot to update the viewport
		# buffers before saving them. Fixes frame lag, where some edits arrive
		# after the commit.
		if not on and just_changed:
			VisualServer.force_draw()
			material.commit_sculptor()
	elif action & (Cartographer.Action.PAINT | Cartographer.Action.ERASE | Cartographer.Action.FILL):
		painter.paint_masks(action, pos, material.selected)
		if not on and just_changed:
			VisualServer.force_draw()
			material.commit_painter()

# TODO: Replace this with a threaded version?
# This hacky little method only gets the pixel data from the texture in
# intervals, because get_data() is an expensive op, and we only need to refresh
# the heightmap data at best after a frame tick, but slower updates are viable.
var _heightmap_data = null
var _heightmap_data_tick = 0
func _update_heightmap_data(enabled: bool = true):
	if _heightmap_data == null or (enabled and _heightmap_data_tick == 0):
		_heightmap_data = material.get_height_map().get_data()
	if enabled and _heightmap_data_tick == 0:
		_heightmap_data_tick = 1
		yield(get_tree().create_timer(0.35), "timeout")
		_heightmap_data_tick = 0

# This class provides a thread for sampling the heigthmap texture in intervals,
# because get_data() is an expensive op, and we only need to refresh
# the heightmap data at best after a frame tick, but slower updates are viable. 
var hmfetcher
class HeightmapFetcher extends Reference:
	var heightmap: Texture
	var thread: Thread = Thread.new()
	var gate: Mutex = Mutex.new()
	var tick: Semaphore = Semaphore.new()
	var data: Image = null
	var _run = true
	
	func _init(hm: Texture):
		heightmap = hm
		data = heightmap.get_data()
		var err = thread.start(self, "worker")
	
	func _exit():
		_run = false
		tick.post()
		thread.wait_to_finish()
	
	func update():
		if gate.try_lock() == OK:
			tick.post()
			gate.unlock()
	
	func worker(arg):
		while _run:
			data = heightmap.get_data()
			gate.unlock()
			tick.wait()
			gate.lock()
			OS.delay_msec(350)

func intersect_ray(from: Vector3, dir: Vector3, refresh: bool = true):
	from = transform.xform_inv(from)
	
	var pts = Cartographer.aabb_intersect_ray(_aabb, from, dir)
	if pts == null:
		return null
	
	var to = pts[-1]
	from = pts[0]
	
#	_update_heightmap_data(refresh)
#	var hm = _heightmap_data
	if refresh:
		hmfetcher.update()
	var hm = hmfetcher.data
	var hm_size = hm.get_size() - Vector2(1, 1)
	var pos = from
	var ret = null
	var rng = ceil((to - from).length())
	
	hm.lock()
	for i in rng:
		pos += dir
		var x = (pos.x + diameter/2) / diameter * hm_size.x
		x = clamp(x, 0, hm_size.x)
		var y = (pos.z + diameter/2) / diameter * hm_size.y
		y = clamp(y, 0, hm_size.y)
		var pix = hm.get_pixel(x, y)
		if pos.y <= pix.r * height:
			ret = pos
			break
	hm.unlock()
	return ret
