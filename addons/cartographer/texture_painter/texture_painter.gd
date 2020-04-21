tool
extends Viewport
class_name TexturePainter

export(Texture) var src: Texture setget load
export(Material) var material: Material setget _set_material, _get_material

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
	_cvi.texture = load("res://addons/cartographer/rect_green.png")
#	_cvi.material.set_shader_param("texture", load("res://addons/cartographer/rect_green.png"))

func load(t: Texture):
	src = t
	#_cvi.texture = load("res://addons/cartographer/rect_green.png")
	#_cvi.material.set_shader_param("base_tex")

func save(i: Image):
	i.copy_from(_vp.get_texture().get_data())

func _set_material(m: Material):
	print(_cvi.get_size())
	_cvi.material = m

func _get_material():
	return _cvi.material

func clear():
	print("CLEAR")
	_cvi.material.set_shader_param("clear", true)

func paint(pos: Vector2, color: Color):
	_cvi.material.set_shader_param("clear", false)
	_cvi.material.set_shader_param("brush_pos", pos)
