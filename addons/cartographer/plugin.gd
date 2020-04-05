tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("res://addons/cartographer/cartographer.tscn").instance()
	#add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	add_control_to_bottom_panel(dock, "Cartographer")
	dock.go()

func _exit_tree():
	#remove_control_from_docks(dock)
	remove_control_from_bottom_panel(dock)
	dock.free()
