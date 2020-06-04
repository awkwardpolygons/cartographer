extends EditorInspectorPlugin
class_name CartoTerrainInspector

func can_handle(object):
	return object is CartoTerrain

func parse_property(object, type, path, hint, hint_text, usage):
	if object == null:
		return false
	
	var prop = object.get(path)
	if prop is CartoTerrainLayers:
		var ed = CartoTerrainLayersEditor.new()
		ed.visible = true
		add_property_editor("terrain_layers", ed)
		return true
	return false
