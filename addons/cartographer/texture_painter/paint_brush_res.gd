tool
extends Resource
class_name PaintBrush

enum MaskChannel {RED, GREEN, BLUE, ALPHA}
export(Texture) var brush_mask: Texture setget set_brush_mask
export(MaskChannel) var mask_channel;
export(float, 0, 1, 0.01) var brush_strength: float = 0.5 setget set_brush_strength
export(float, 0.1, 8, 0.01) var brush_scale: float = 1 setget set_brush_scale
export(float, 0, 1, 0.01) var brush_rotation: float setget set_brush_rotation
export(float, 0, 100, 0.01) var brush_spacing: float setget set_brush_spacing
export(float, 0, 1, 0.01) var brush_strength_jitter: float setget set_brush_strength_jitter
export(float, 0, 1, 0.01) var brush_scale_jitter: float setget set_brush_scale_jitter
export(float, 0, 1, 0.01) var brush_rotation_jitter: float setget set_brush_rotation_jitter
export(float, 0, 1, 0.01) var brush_spacing_jitter: float setget set_brush_spacing_jitter

func set_brush_mask(t: Texture):
	brush_mask = t
	emit_signal("changed")

func set_brush_strength(s: float):
	brush_strength = clamp(s, 0, 1)
	emit_signal("changed")

func set_brush_strength_jitter(j: float):
	brush_strength_jitter = clamp(j, 0, 1)
	emit_signal("changed")

func set_brush_scale(s: float):
	brush_scale = clamp(s, 0, 8)
	emit_signal("changed")

func set_brush_scale_jitter(j: float):
	brush_scale_jitter = clamp(j, 0, 1)
	emit_signal("changed")

func set_brush_rotation(r: float):
	brush_rotation = clamp(r, 0, 1)
	emit_signal("changed")

func set_brush_rotation_jitter(j: float):
	brush_rotation_jitter = clamp(j, 0, 1)
	emit_signal("changed")

func set_brush_spacing(s: float):
	brush_spacing = clamp(s, 0, 100)
	emit_signal("changed")

func set_brush_spacing_jitter(j: float):
	brush_spacing_jitter = clamp(j, 0, 1)
	emit_signal("changed")

func _init(mask = null):
	if mask is Texture:
		brush_mask = mask

func get_relative_brush_scale(rel: float):
	var size = brush_mask.get_size()
	return brush_scale * (max(size.x, size.y) / rel)

func get_brush_channel_as_color():
	var clr = Color(0, 0, 0, 0)
	clr[mask_channel] = 1
	return clr
