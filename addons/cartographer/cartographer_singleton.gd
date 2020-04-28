tool
extends Node

var brushes: PaintBrushes

func _init():
	_load()

func _ready():
	pass # Replace with function body.

func _load():
	if ResourceLoader.exists("res://addons/cartographer/data/brushes.tres"):
		brushes = ResourceLoader.load("res://addons/cartographer/data/brushes.tres")
	else:
		brushes = PaintBrushes.new()
		ResourceSaver.save("res://addons/cartographer/data/brushes.tres", brushes)
