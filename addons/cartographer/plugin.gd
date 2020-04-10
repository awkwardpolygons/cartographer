tool
extends EditorPlugin

var dock
var editor = get_editor_interface()

func _enter_tree():
	dock = preload("res://addons/cartographer/cartographer.tscn").instance()
	#add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	add_control_to_bottom_panel(dock, "Cartographer")
	dock.hide()
	editor.get_selection().connect("selection_changed", self, "_on_selection_changed", [dock])

func _on_selection_changed(dock):
	var selected = editor.get_selection().get_selected_nodes()
	
	if len(selected) == 1:
		var node = selected[0]
		if node.get("isCartoTerrain"):
			make_bottom_panel_item_visible(dock)
			node.update_layer_data()
		elif node.get("isCartoLayer"):
			make_bottom_panel_item_visible(dock)
		else:
			hide_bottom_panel()
		

func _exit_tree():
	#remove_control_from_docks(dock)
	remove_control_from_bottom_panel(dock)
	dock.free()
