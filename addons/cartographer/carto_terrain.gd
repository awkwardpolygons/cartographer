tool
extends CSGMesh

class_name CartoTerrain, "res://addons/cartographer/terrain_icon.svg"

export(Vector2) var size: Vector2 = Vector2(20, 20) setget set_size
var isCartoTerrain: bool = true
var csg: CSGMesh = self

func set_size(s: Vector2):
	size = s
	csg.mesh.size = s

func _enter_tree():
	#if csg == null:
	#	csg = CSGMesh.new()
	#	add_child(csg)
	if csg.mesh == null:
		csg.mesh = PlaneMesh.new()
		csg.mesh.size = size
	
func _ready():
	#var this = CartoTerrain           # reference to the script
	print(csg.mesh)
