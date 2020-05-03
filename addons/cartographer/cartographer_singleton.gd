tool
extends Node

var brushes: PaintBrushes
var active_brush: PaintBrush setget _set_active_brush, _get_active_brush

signal active_brush_changed

func _init():
	self.load()

func _set_active_brush(br: PaintBrush):
	active_brush = br
	emit_signal("active_brush_changed", br)

func _get_active_brush():
	return active_brush

func load():
	if ResourceLoader.exists("res://addons/cartographer/data/brushes.tres"):
		brushes = ResourceLoader.load("res://addons/cartographer/data/brushes.tres")
	else:
		brushes = PaintBrushes.new()

func save():
	ResourceSaver.save("res://addons/cartographer/data/brushes.tres", brushes)
