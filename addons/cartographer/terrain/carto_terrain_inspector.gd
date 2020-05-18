extends EditorInspectorPlugin
class_name CartoTerrainInspector

var Editor = preload("res://addons/cartographer/terrain/carto_terrain_layers_editor.tscn")

func can_handle(object):
	return object is CartoTerrain

func parse_property(object, type, path, hint, hint_text, usage):
	var prop = object.get(path)
	if prop is CartoTerrainLayers:
		var editor = Editor.instance()
		editor.terrain_layers = prop
		add_custom_control(editor)
		return true
	return false
