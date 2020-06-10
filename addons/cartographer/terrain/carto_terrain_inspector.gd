extends EditorInspectorPlugin
class_name CartoTerrainInspector

const LayersEditor = preload("res://addons/cartographer/terrain/carto_terrain_layers_editor/layers_editor.gd")

class Test extends EditorProperty:
	func _ready():
		prints("Test:", get_edited_object(), get_edited_property())
		label = "Textures"
		var box = VBoxContainer.new()
		var btn = Button.new()
		btn.text = "Button"
		box.add_child(btn)
		box.rect_min_size = Vector2(0, 300)
		add_child(box)
		set_bottom_editor(box)

func can_handle(object):
	return object is CartoTerrainLayers

func parse_property(object, type, path, hint, hint_text, usage):
#	prints(path, object, object.get(path), type, hint, hint_text, usage)
	if object == null:
		return false
	
	if path == "textures":
		add_property_editor_for_multiple_properties("Textures", PoolStringArray(["textures", "use_triplanar"]), LayersEditor.new())
		return true
	elif path == "selected" or path == "use_triplanar":
		return true
	
	# TODO: Cache the editor
#	var prop = object.get(path)
#	if prop is CartoTerrainLayers:
#		var ed = CartoTerrainLayersEditor.new()
#		ed.visible = true
#		add_property_editor("terrain_layers", ed)
#		return true
#	return false
