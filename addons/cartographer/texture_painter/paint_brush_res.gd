extends Resource
class_name PaintBrush

export(Texture) var brush_mask: Texture setget set_brush_mask
export(float, 0, 1) var brush_strength: float = 0.5 setget set_brush_strength
export(float, 0, 1) var brush_strength_jitter: float setget set_brush_strength_jitter
export(float, 0, 2) var brush_scale: float = 1 setget set_brush_scale
export(float, 0, 1) var brush_scale_jitter: float setget set_brush_scale_jitter
export(float, 0, 1) var brush_rotation: float setget set_brush_rotation
export(float, 0, 1) var brush_rotation_jitter: float setget set_brush_rotation_jitter
export(float, 0, 100, 0.1) var brush_spacing: float setget set_brush_spacing
export(float, 0, 1) var brush_spacing_jitter: float setget set_brush_spacing_jitter

func set_brush_mask(t: Texture):
	brush_mask = t

func set_brush_strength(s: float):
	brush_strength = clamp(s, 0, 1)

func set_brush_strength_jitter(j: float):
	brush_strength_jitter = clamp(j, 0, 1)

func set_brush_scale(s: float):
	brush_scale = clamp(s, 0, 2)

func set_brush_scale_jitter(j: float):
	brush_scale_jitter = clamp(j, 0, 1)

func set_brush_rotation(r: float):
	brush_rotation = clamp(r, 0, 1)

func set_brush_rotation_jitter(j: float):
	brush_rotation_jitter = clamp(j, 0, 1)

func set_brush_spacing(s: float):
	brush_spacing = clamp(s, 0, 100)

func set_brush_spacing_jitter(j: float):
	brush_spacing_jitter = clamp(j, 0, 1)
