extends EditorInspectorPlugin
class_name CartoTerrainInspector

const LayersEditor = preload("res://addons/cartographer/terrain/carto_terrain_layers_editor/layers_editor.gd")

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
