tool
extends Viewport
class_name TexturePainter

enum Action {NONE, PAINT, ERASE, CLEAR}

export(Texture) var src: Texture setget load
export(Material) var material: Material setget _set_material, _get_material
var brush: PaintBrush setget _set_brush, _get_brush

var _vp: Viewport
var _cvi: TextureRect
#var _shader = preload("res://addons/cartographer/texture_painter/terrain_painter_shader.tres")
var _shader = preload("res://addons/cartographer/texture_painter/texture_painter.shader")


func _init():
	#_vp = Viewport.new()
	_vp = self
	_vp.size = Vector2(512, 512)
	_vp.hdr = false
	_vp.disable_3d = true
	_vp.usage = Viewport.USAGE_2D
	_vp.render_target_v_flip = true
	_vp.render_target_clear_mode = Viewport.CLEAR_MODE_NEVER
	_vp.render_target_update_mode = Viewport.UPDATE_ALWAYS
	
	_cvi = TextureRect.new()
	_cvi.rect_min_size = _vp.size
	_cvi.rect_size = _vp.size
	_cvi.expand = true
	_cvi.stretch_mode = TextureRect.STRETCH_SCALE
	_vp.add_child(_cvi)
	
	_cvi.material = ShaderMaterial.new()
	_cvi.material.shader = _shader
	_cvi.texture = load("res://largetex.tres")
#	_cvi.material.set_shader_param("texture", load("res://addons/cartographer/rect_green.png"))

func _set_material(m: Material):
	_cvi.material = m

func _get_material():
	return _cvi.material

func _set_brush(br: PaintBrush):
	brush = br
	_cvi.material.set_shader_param("brush_mask", brush.brush_mask)
	_cvi.material.set_shader_param("brush_strength", brush.brush_strength)
	_cvi.material.set_shader_param("brush_scale", brush.brush_scale)
	_cvi.material.set_shader_param("brush_rotation", brush.brush_rotation)

func _get_brush():
	return brush

func load(t: Texture):
	src = t
	#_cvi.texture = load("res://addons/cartographer/rect_green.png")
	#_cvi.material.set_shader_param("base_tex")

func save(i: Image):
	i.copy_from(_vp.get_texture().get_data())

func clear():
	print("CLEAR")
	# TODO: Temporary for shader updates during dev:
	_cvi.material.shader = load("res://addons/cartographer/texture_painter/texture_painter.shader")
	_cvi.material.set_shader_param("action", Action.CLEAR)

func paint(pos: Vector2, brush: PaintBrush):
	self.brush = brush
	_cvi.material.set_shader_param("action", Action.PAINT)
	_cvi.material.set_shader_param("brush_pos", pos)

func stop():
	_cvi.material.set_shader_param("action", Action.NONE)

func erase(pos: Vector2):
	_cvi.material.set_shader_param("action", Action.ERASE)
	_cvi.material.set_shader_param("brush_pos", pos)
