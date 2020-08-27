tool
extends ColorRect

enum TextureChannel {RED = 1, GREEN = 2, BLUE = 4, ALPHA = 8}
export(int) var idx: int setget set_idx
export(TextureArray) var texarr: TextureArray setget set_texarr
export(TextureChannel) var channel: int setget set_channel

func set_idx(i):
	idx = i
	if material:
		material.set_shader_param("idx", idx)

func set_texarr(ta):
	texarr = ta
	if material:
		material.set_shader_param("texarr", texarr)

func set_channel(ch):
	channel = ch
	if material:
		material.set_shader_param("channel", channel)

func _init():
	material = ShaderMaterial.new()
	material.shader = preload("res://addons/cartographer/terrain/carto_multi_texture_editor/layer.shader")

func _ready():
	material.set_shader_param("idx", idx)
	material.set_shader_param("texarr", texarr)

func get_combined_minimum_size() -> Vector2:
	var size = .get_combined_minimum_size()
	size.x = max(rect_size.x, size.x)
	size.y = max(rect_size.y, size.x)
	return size
