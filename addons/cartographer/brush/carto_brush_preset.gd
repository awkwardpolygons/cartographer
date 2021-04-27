tool
extends Resource
class_name CartoBrushPreset

enum Mode {ADD, SUB, SET, SMOOTH}
export(Texture) var mask: Texture
export(float, 0.1, 100.0, 0.1) var scale: float = 1.0
export(float, 0.0, 360.0, 0.1) var rotation: float = 0.0
export(float, 0.1, 2.0, 0.01) var spacing: float = 0.25
export(float, 0.1, 1.0, 0.1) var strength: float = 0.5

#export(float, 0.0, 1.0, 0.1) var jitter_scale: float = 0.0
#export(float, 0.0, 1.0, 0.1) var jitter_rotation: float = 0.0
#export(float, 0.0, 1.0, 0.1) var jitter_spacing: float = 0.0
#export(float, 0.0, 1.0, 0.1) var jitter_strength: float = 0.0

export(Mode) var mode
