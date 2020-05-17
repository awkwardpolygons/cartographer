extends EditorInspectorPlugin
class_name CartoTerrainInspector

var Editor = preload("res://addons/cartographer/carto_terrain_layers_editor.tscn")

func can_handle(object):
	return object is CartoTerrain

#func parse_begin(object):
#	print("CartoTerrainInspector.parse_begin: ", object)
#
#func parse_category(object, category):
#	print("CartoTerrainInspector.parse_category:")
#	print(object, category)

func parse_property(object, type, path, hint, hint_text, usage):
	var prop = object.get(path)
	if prop is CartoTerrainLayers:
		print("CartoTerrainInspector.parse_property:")
		print(object, ", ", type, ", ",  path, ", ",  hint, ", ",  hint_text, ", ",  usage)
		print("------------------")
		print(prop, ", ", prop.resource_path, ", ", prop.resource_name)
		print(prop.textures, ", ", prop.textures.resource_path, ", ", prop.resource_name, ", ",len(prop.textures.array))
		var editor = Editor.instance()
		editor.terrain_layers = prop
		add_custom_control(editor)
		return true
