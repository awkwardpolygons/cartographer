tool
extends Viewport
class_name HeightmapPicker

const _shader = preload("res://addons/cartographer/terrain/heightmap_picker.shader")

export(Texture) var heightmap: Texture setget _set_heightmap
export(float) var diameter: float
export(float) var height: float
export(Vector3) var from: Vector3 setget _set_from
export(Vector3) var direction: Vector3 setget _set_direction

var _cvi: TextureRect
var _img: Image

func _set_heightmap(hm: Texture):
	heightmap = hm
	if _cvi.material:
		_cvi.material.set_shader_param("heightmap", heightmap)

func _set_from(frm):
	set_ray(frm, direction)

func _set_direction(dir):
	set_ray(from, dir)

func _init():
	size = Vector2(1024, 2)
	transparent_bg = true
	hdr = true
	keep_3d_linear = true
	disable_3d = true
	usage = Viewport.USAGE_3D
	render_target_v_flip = true
	render_target_clear_mode = Viewport.CLEAR_MODE_NEVER
	render_target_update_mode = Viewport.UPDATE_ALWAYS
	
	_cvi = TextureRect.new()
	_cvi.rect_min_size = size
	_cvi.rect_size = size
#	_cvi.expand = true
#	_cvi.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_cvi)
	
	_cvi.material = ShaderMaterial.new()
	_cvi.material.shader = _shader
	_img = Image.new()
	_img.create(size.x, 2, false, Image.FORMAT_RGBAH)
	_cvi.texture = ImageTexture.new()
	_cvi.texture.create_from_image(_img)
	

func set_ray(frm: Vector3, dir: Vector3):
	from = frm
	direction = dir
	
	var size = heightmap.get_size() - Vector2(1, 1)
	
	_img.lock()
	for i in _img.get_width():
		frm += dir
		var x = (frm.x + diameter/2) / diameter * size.x
		x = clamp(x, 0, size.x)
		var z = (frm.z + diameter/2) / diameter * size.y
		z = clamp(z, 0, size.y)
		var c = Color(x, frm.y / height, z, 0)
		_img.set_pixel(i, 0, c)
		_img.set_pixel(i, 1, c)
	_img.unlock()
	_cvi.texture.set_data(_img)

func get_point():
	var img = get_texture().get_data()
	var size = heightmap.get_size() - Vector2(1, 1)
	var pnt = null
	
	img.lock()
	_img.lock()
	for i in img.get_width():
		var px = img.get_pixel(i, 0)
		var px2 = img.get_pixel(i, 1)
		if px.a > 0:
			pnt = Vector2(px.r, px.b) / size
			break
	img.unlock()
	_img.unlock()
	
	return pnt
