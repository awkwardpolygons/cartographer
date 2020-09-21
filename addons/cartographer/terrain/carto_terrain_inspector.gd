extends EditorInspectorPlugin
class_name CartoTerrainInspector

# const LayersEditor = preload("res://addons/cartographer/terrain/carto_terrain_material_editor/layers_editor.gd")
const MultiTextureEditor = preload("res://addons/cartographer/terrain/carto_multi_texture_editor/editor.gd")
const FlagsEditor = preload("res://addons/cartographer/ui/flags_editor.gd")
const skip_props = ["selected", "shader"]
var undo_redo: UndoRedo

func can_handle(object):
	return object is CartoMultiTexture or object is CartoTerrainMaterial

func parse_property(object, type, path, hint, hint_text, usage):
#	prints(path, object, object.get(path), type, hint, hint_text, usage)
	if object == null:
		return false
	
	if object is CartoMultiTexture and path == "flags":
		var mted = MultiTextureEditor.new()
		mted.texarr = object as CartoMultiTexture
		mted.undo_redo = undo_redo
#		add_property_editor_for_multiple_properties("Layers", PoolStringArray(["data"]), mted)
#		add_property_editor("data", mted)
		add_custom_control(mted)
	elif object is CartoTerrainMaterial and hint == PROPERTY_HINT_FLAGS:
		var flags_ed = FlagsEditor.new()
		flags_ed.hint_text = hint_text
		add_property_editor(path, flags_ed)
		return true
	elif path in skip_props:
		return true
