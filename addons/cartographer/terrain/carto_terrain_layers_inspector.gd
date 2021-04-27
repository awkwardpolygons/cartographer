tool
extends EditorInspectorPlugin
class_name CartoTerrainLayersInspector

const Editor = preload("res://addons/cartographer/ui/carto_terrain_layers/editor.gd")

func can_handle(object):
#	prints("--->", object)
	return object is CartoTerrainLayers

func parse_property(object, type, path, hint, hint_text, usage):
#	prints("--->", path, object, object.get(path), type, hint, hint_text, usage)
	if object == null:
		return false
	if path == "layers":
#		prints(object is CartoTerrainLayers)
		var ed = Editor.new()
		add_custom_control(ed)
		return true
	return false
