tool
extends Node

enum Action {NONE = 0, JUST_CHANGED = 1, ON = 2, RAISE = 4, LOWER = 8, PAINT = 16, ERASE = 32, FILL = 64, CLEAR = 128}
# TODO: A better approach:
#enum Mode {SCULPT = 1, PAINT = 2}
#enum Tool {RESET, FILL, BRUSH, SMOOTH, SHARPEN} # Use value for add, remove, eg. Vector3(-1) for remove
var brushes: PaintBrushes
var active_brush: PaintBrush setget _set_active_brush, _get_active_brush
var undo_redo: UndoRedo
var action: int = Action.RAISE
var editor: EditorInterface

signal active_brush_changed

func _init():
	self.load()

func _set_active_brush(br: PaintBrush):
	if active_brush:
		active_brush.disconnect("changed", self, "emit_active_brush_changed")
	active_brush = br
	active_brush.connect("changed", self, "emit_active_brush_changed", [active_brush])
	emit_active_brush_changed(active_brush)

func emit_active_brush_changed(br: PaintBrush):
	emit_signal("active_brush_changed", br)

func _get_active_brush():
	return active_brush

func get_action(alt:bool=false):
	if not alt:
		return action
	match action:
		Action.RAISE:
			return Action.LOWER
		Action.LOWER:
			return Action.RAISE
		Action.PAINT:
			return Action.ERASE
		Action.ERASE:
			return Action.PAINT
		Action.FILL:
			return Action.CLEAR
		Action.CLEAR:
			return Action.FILL

func load():
	if ResourceLoader.exists("res://addons/cartographer/data/brushes.tres"):
		brushes = ResourceLoader.load("res://addons/cartographer/data/brushes.tres")
	else:
		brushes = PaintBrushes.new()

func save():
	ResourceSaver.save("res://addons/cartographer/data/brushes.tres", brushes)

# Helper function
func aabb_intersect_ray(aabb: AABB, from: Vector3, dir: Vector3, margin: float=0.04):
	var size = aabb.size
	var planes = Geometry.build_box_planes(size / 2)
	from.y -= size.y/2
	var pts = []
	for plane in planes:
		var pt = plane.intersects_ray(from, dir)
		if pt == null \
			or abs(pt.x) > size.x / 2 + margin \
			or abs(pt.y) > size.y / 2 + margin \
			or abs(pt.z) > size.z / 2 + margin:
			continue
		pt.y +=  size.y/2
		pts.append(pt)
	
	from.y += size.y/2
	if len(pts) >= 2:
		var lrg = pts[0]
		var sml = pts[0]
		for pt in pts:
			var v = pt.length_squared()
			lrg = pt if v > lrg.length_squared() else lrg
			sml = pt if v < sml.length_squared() else sml
		return [lrg, sml]
	elif len(pts) == 1 and aabb.has_point(from):
		return [from, pts[0]]
	else:
		return null
