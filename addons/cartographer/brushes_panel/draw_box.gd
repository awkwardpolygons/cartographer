tool
extends VBoxContainer

export(String) var text: String = ""
export(String) var alt_text: String = ""
export(bool) var pressed: bool = false setget _set_pressed, _get_pressed
var icon_opened = preload("res://addons/cartographer/brushes_panel/icon_draw_opened.svg")
var icon_closed = preload("res://addons/cartographer/brushes_panel/icon_draw_closed.svg")

func _ready():
	for child in get_children():
		if child.name == "Handle" or child.name == "Draw":
			continue
		.remove_child(child)
		$Draw.add_child(child)
	$Draw.visible = $Handle/Button.pressed
	$Handle/Button.text = text if self.pressed else alt_text
	$Handle/Button.icon = icon_opened if self.pressed else icon_closed

func _set_pressed(p: bool):
	$Handle/Button.pressed = p
#	var b = find_node("Button")
#	if b:
#		b.set_pressed(p)

func _get_pressed():
#	if find_node("Button"):
	return $Handle/Button.pressed

func add_child(node: Node, legible_unique_name: bool = false):
#	if Engine.editor_hint:
#		.add_child(node, legible_unique_name)
#	else:
	$Draw.add_child(node, legible_unique_name)

func remove_child(node: Node):
#	if Engine.editor_hint:
#		.remove_child(node)
#	else:
	$Draw.remove_child(node)

func get_children() -> Array:
#	if Engine.editor_hint:
#		return .get_children()
#	else:
	return $Draw.get_children()

func _on_toggled(toggled):
	$Handle/Button.text = text if toggled else alt_text
	$Handle/Button.icon = icon_opened if self.pressed else icon_closed
	$Draw.visible = toggled
