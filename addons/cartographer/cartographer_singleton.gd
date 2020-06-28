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
