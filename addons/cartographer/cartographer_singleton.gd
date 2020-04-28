tool
extends Node

var brushes: PaintBrushes

func _init():
	self.load()

func load():
	if ResourceLoader.exists("res://addons/cartographer/data/brushes.tres"):
		brushes = ResourceLoader.load("res://addons/cartographer/data/brushes.tres")
	else:
		brushes = PaintBrushes.new()

func save():
	ResourceSaver.save("res://addons/cartographer/data/brushes.tres", brushes)
