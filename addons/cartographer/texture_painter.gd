tool
extends Viewport
class_name TexturePainter

var _vp: Viewport
var _cvi: ColorRect
export(Texture) var src: Texture setget set_src
export(Material) var material: Material setget _set_material, _get_material

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
	
	_cvi = ColorRect.new()
	_cvi.rect_min_size = _vp.size
	_cvi.rect_size = _vp.size
	#_cvi.stretch_mode = TextureRect.STRETCH_SCALE_ON_EXPAND
	#_cvi.expand = true

func _ready():
	print(_vp.get_child_count(), _vp.get_child(0))
	print(_cvi.rect_size)
	_vp.add_child(_cvi)
#	_cvi.owner = _vp
	print(_vp.get_child_count(), _vp.get_child(0))
	print(_cvi.rect_size)

func set_src(t: Texture):
	src = t
	#_cvi.texture = t

func put_src(i: Image):
	i.copy_from(_vp.get_texture().get_data())

func _set_material(m: Material):
	print(_cvi.rect_size, _cvi.rect_min_size, _cvi.margin_right)
	_cvi.material = m
	print("_set_material ", _cvi.material.shader)

func _get_material():
	return _cvi.material

func paint(pos: Vector2, color: Color):
	#print(pos)
	_cvi.material.set_shader_param("brush_pos", pos)
