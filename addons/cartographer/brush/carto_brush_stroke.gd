tool
extends Node2D
class_name CartoBrushStroke

export var curve: Curve2D setget set_curve
export var mesh: Mesh setget set_mesh
export var texture: Texture
var multimesh: MultiMesh
var _last_index: int = 0

func set_curve(v: Curve2D):
	curve = v
	if curve != null:
		update_stroke()

func set_mesh(v: Mesh):
	mesh = v
	multimesh.mesh = mesh

func _init():
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.color_format = MultiMesh.COLOR_FLOAT
	multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_FLOAT
	multimesh.instance_count = 1000
	set_mesh(preload("res://addons/cartographer/meshes/brush_stroke.mesh"))
	texture = preload("res://addons/cartographer/brush/1.png")
	curve = Curve2D.new()

func _draw():
	if mesh and texture:
		draw_multimesh(multimesh, texture, null)
#		var bpts = curve.get_baked_points()
#		for pos in bpts:
#			draw_circle(pos, 2.0, Color.bisque)
#		for i in curve.get_point_count():
#			var pos = curve.get_point_position(i)
#			var a = pos + curve.get_point_in(i)
#			var b = pos + curve.get_point_out(i)
#			draw_circle(pos, 5.0, Color.aqua)
##			draw_circle(a, 2.0, Color.white)
#			draw_circle(b, 2.0, Color.white)

func _ready():
	pass

func add_point(position: Vector2, speed: Vector2 = Vector2(0, 0), pressure: float = 0.0):
	if not curve:
		return
	
	var point_in: Vector2 = Vector2(0, 0)
	var point_out: Vector2 = Vector2(0, 0)
	var at_position: int = -1
	
	var pnt_count = curve.get_point_count()
	if pnt_count > 1:
		var prv_point = curve.get_point_position(pnt_count - 1)
		var relative = position - prv_point
		var tangent = relative.normalized()
		var distance = relative.length_squared()
		prints(speed / 512.0)
#		if distance > 1000.0:
#			point_out = tangent * sqrt(distance) / 2.0
##			point_out = speed.normalized() * sqrt(distance) / 2.0
##			point_out = tangent * speed.length() / sqrt(distance)
##			point_out = speed / sqrt(distance) / 3.0
		if distance > 250.0:
			curve.add_point(position, point_in, point_out, at_position)
		else:
			return
	else:
		curve.add_point(position, point_in, point_out, at_position)
	update_stroke()
#	update()

func update_stroke(from = 0):
	if not (mesh and texture):
		return
	
	var stroke_lth: float = curve.get_baked_length()
	var tip_size = mesh.get_aabb().size
	var stride = tip_size.x * 0.2
	stroke_lth = max(stroke_lth, stride)
	var inst: int = stroke_lth / stride
#	prints(inst)
	
	multimesh.visible_instance_count = inst
	
#	_last_index = _last_index if _last_index > 0 else _last_index - 1
	var offset = _last_index * stride
	for i in range(_last_index, inst):
#		prints("-->", i)
		_last_index = i
		var pos = curve.interpolate_baked(offset, false)
		var ahead = curve.interpolate_baked(offset + stride, false)
		var tangent = (ahead - pos).normalized()
		var normal = -tangent.tangent()
#		pos = pos if curve.get_point_count() > 0 else curve.get_point_position(0)
#		prints(pos)
		offset += stride
#		prints("position:", pos)
		multimesh.set_instance_transform_2d(i, Transform2D(normal.angle(), pos))
		multimesh.set_instance_custom_data(i, Color(i+1, 0, 0, 0))
#		multimesh.set_instance_color(i, Color(0.5 - tangent.x/2.0, 0.5 - tangent.y/2.0, 0.0, 1.0))
		multimesh.set_instance_color(i, Color.darksalmon)
#	_last_index += 1
	
	update()

func done():
	multimesh.instance_count = 0


var is_painting: bool
var brush_stroke = self

#func _input(event):
#	prints(event)
#	if is_painting and event is InputEventMouseMotion:
#		brush_stroke.add_point(event.position, event.speed, event.pressure)
#	elif event is InputEventMouseButton and event.pressed:
#		brush_stroke.add_point(event.position)
#		is_painting = true
#	elif event is InputEventMouseButton and !event.pressed:
#		is_painting = false
