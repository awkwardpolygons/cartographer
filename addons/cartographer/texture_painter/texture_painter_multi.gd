extends Node
class_name TexturePainterMulti

enum Action {NONE, PAINT, ERASE, CLEAR}

var brush: PaintBrush setget _set_brush, _get_brush
var _shader = preload("res://addons/cartographer/texture_painter/texture_painter.shader")

func _set_brush(br: PaintBrush):
	brush = br
	_set_shader_params([["brush_mask", brush.brush_mask],
	["brush_strength", brush.brush_strength],
	["brush_scale", brush.brush_scale],
	"brush_rotation", brush.brush_rotation])

func _get_brush():
	return brush

func _ready():
	pass

func _set_shader_params(params: Array, exclude={}):
	for i in get_child_count():
		var cv = get_child(i).get_child(0)
		for param in params:
			if not exclude[i]:
				cv.material.set_shader_param(param[0], param[1])

func add_layer():
	var vp = Viewport.new()
	var cvi = TextureRect.new()
	
	vp.size = Vector2(512, 512)
	vp.hdr = false
	vp.disable_3d = true
	vp.usage = Viewport.USAGE_2D
	vp.render_target_v_flip = true
	vp.render_target_clear_mode = Viewport.CLEAR_MODE_NEVER
	vp.render_target_update_mode = Viewport.UPDATE_ALWAYS
	
	cvi.name = "Texture"
	cvi.rect_min_size = vp.size
	cvi.rect_size = vp.size
	cvi.expand = true
	cvi.stretch_mode = TextureRect.STRETCH_SCALE
	vp.add_child(cvi)
	self.add_child(vp)
	
	cvi.material = ShaderMaterial.new()
	cvi.material.shader = _shader

func rem_layer(id: int):
	remove_child(get_child(id))
