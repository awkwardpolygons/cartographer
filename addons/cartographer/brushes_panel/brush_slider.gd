tool
extends Control

signal changed
signal value_changed

export(String) var label: String setget _set_label, _get_label
export(float) var min_value: float = 0 setget _set_min_value, _get_min_value
export(float) var max_value: float = 100 setget _set_max_value, _get_max_value
export(float) var step: float = 1 setget _set_step, _get_step
export(float) var value: float setget _set_value, _get_value
export(bool) var disabled: bool setget _set_disabled, _get_disabled
var ratio: float setget , _get_ratio
var _brush
var _prop

func _on_changed():
	emit_signal("changed")

func _on_value_changed(value):
	emit_signal("value_changed", value)

func _ready():
	$BrushSliderContainer/VBoxContainer/ValueSlider.share($BrushSliderContainer/MarginContainer/ValueEdit)

func _set_label(text: String):
	$BrushSliderContainer/VBoxContainer/Label.text = text

func _get_label():
	return $BrushSliderContainer/VBoxContainer/Label.text

func _set_min_value(min_value: float):
	$BrushSliderContainer/VBoxContainer/ValueSlider.min_value = min_value
	$BrushSliderContainer/MarginContainer/ValueEdit.min_value = min_value

func _get_min_value():
	return $BrushSliderContainer/VBoxContainer/ValueSlider.min_value

func _set_max_value(max_value: float):
	$BrushSliderContainer/VBoxContainer/ValueSlider.max_value = max_value
	$BrushSliderContainer/MarginContainer/ValueEdit.max_value = max_value

func _get_max_value():
	return $BrushSliderContainer/VBoxContainer/ValueSlider.max_value

func _set_step(step: float):
	$BrushSliderContainer/VBoxContainer/ValueSlider.step = step
	$BrushSliderContainer/MarginContainer/ValueEdit.step = step

func _get_step():
	return $BrushSliderContainer/VBoxContainer/ValueSlider.step

func _set_value(value: float):
	$BrushSliderContainer/VBoxContainer/ValueSlider.value = value
	$BrushSliderContainer/MarginContainer/ValueEdit.value = value

func _get_value():
	return $BrushSliderContainer/VBoxContainer/ValueSlider.value

func _get_ratio():
	return $BrushSliderContainer/VBoxContainer/ValueSlider.ratio

func _set_disabled(b: bool):
	$BrushSliderContainer/VBoxContainer/ValueSlider.editable = not b
	$BrushSliderContainer/MarginContainer/ValueEdit.editable = not b

func _get_disabled():
	return not $BrushSliderContainer/VBoxContainer/ValueSlider.editable

func bind(brush: PaintBrush, prop: String):
	_brush = brush
	_prop = prop

func unbind():
	_brush = null
	_prop = null

func set_range(rng: Array, val=null):
	self.min_value = float(rng[0]) if len(rng) > 0 else self.min_value
	self.max_value = float(rng[1]) if len(rng) > 1 else self.max_value
	self.step = float(rng[2]) if len(rng) > 2 else self.step
	self.value = val if val else self.value
