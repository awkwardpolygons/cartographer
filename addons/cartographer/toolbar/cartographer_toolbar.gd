tool
extends HBoxContainer

func _enter_tree():
	match Cartographer.action:
		Cartographer.Action.RAISE:
			$Raise.pressed = true
		Cartographer.Action.LOWER:
			$Lower.pressed = true
		Cartographer.Action.PAINT:
			$Paint.pressed = true
		Cartographer.Action.FILL:
			$Fill.pressed = true
	
	$Raise.connect("toggled", self, "_on_mode_selected", [Cartographer.Action.RAISE])
	$Lower.connect("toggled", self, "_on_mode_selected", [Cartographer.Action.LOWER])
	$Paint.connect("toggled", self, "_on_mode_selected", [Cartographer.Action.PAINT])
	$Fill.connect("toggled", self, "_on_mode_selected", [Cartographer.Action.FILL])

func _exit_tree():
	$Raise.disconnect("toggled", self, "_on_mode_selected")
	$Lower.disconnect("toggled", self, "_on_mode_selected")
	$Paint.disconnect("toggled", self, "_on_mode_selected")
	$Fill.disconnect("toggled", self, "_on_mode_selected")

func _on_mode_selected(toggled, action):
	if toggled:
		Cartographer.action = action
