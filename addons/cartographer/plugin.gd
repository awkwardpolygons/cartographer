tool
extends EditorPlugin

const Action = TexturePainter.Action
const BrushesPanel = preload("res://addons/cartographer/brushes_panel/brushes_panel.tscn")

var _action = Action.NONE
var brushes_panel = BrushesPanel.instance()
var editor = get_editor_interface()
var terrain: CartoTerrain
var brush: CartoBrush
var do_paint: bool = false
var inspector_plugin: CartoTerrainInspector

func _init():
	add_autoload_singleton("Cartographer", "res://addons/cartographer/cartographer_singleton.gd")
	inspector_plugin = CartoTerrainInspector.new()
	add_inspector_plugin(inspector_plugin)

func _enter_tree():
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, brushes_panel)
	Cartographer.undo_redo = get_undo_redo()
	editor.get_selection().connect("selection_changed", self, "_on_selection_changed", [brushes_panel])

func _on_selection_changed(brushes_panel):
	var selected = editor.get_selection().get_selected_nodes()
#	print("selected ", selected)
	if len(selected) == 0:
		handles(null)

func _exit_tree():
#	print(brushes_panel)
	remove_control_from_docks(brushes_panel)
	if brushes_panel:
		brushes_panel.free()

func get_plugin_name():
	return "Cartographer"

# TODO: Investigate MultiNodeEdit
func handles(obj: Object):
#	print("handles ", obj)
	if obj is CartoBrush or obj is CartoTerrain:
		return true
#	edit(null)
	return false

func get_terrain_from(obj: Object):
	if obj is EditorSelection:
		obj = obj.get_selected_nodes()[0]
	if obj is CartoBrush:
		obj = obj.get_parent()
	if obj is CartoTerrain:
		return obj
	return null

func get_brush_from(obj: Object):
	if obj is EditorSelection:
		obj = obj.get_selected_nodes()[0]
	if obj is CartoBrush:
		return obj
	return null

func edit(obj: Object):
#	print("EDIT", obj)
	terrain = get_terrain_from(obj)
	brush = get_brush_from(obj)

func make_visible(visible):
	pass

func forward_spatial_gui_input(camera, event):
	var action = get_action(event)
#	print("--> ", action)
	if action == Action.CLEAR:
		terrain.painter.clear()
		return false
	return try_paint(camera, action)

func get_action(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(BUTTON_LEFT):
		_action = Action.PAINT
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		_action = Action.PAINT if event.pressed else Action.NONE
	elif event is InputEventKey and event.scancode == KEY_BACKSPACE:
		_action = Action.CLEAR if event.is_pressed() else Action.NONE
	if event.alt:
		_action = Action.ERASE if _action == Action.PAINT else _action
	else:
		_action = Action.PAINT if _action == Action.ERASE else _action
	return _action

func try_paint(camera, action):
	if action == Action.NONE:
		terrain.painter.stop()
		return false
	
	var viewport = camera.get_viewport()
	var viewport_container = viewport.get_parent()
	var screen_pos = viewport.get_mouse_position() * viewport.size / viewport_container.rect_size
	
	var size = Vector3(terrain.size.x, 0, terrain.size.z)
	var org = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	var pos = terrain.intersect_ray(org, dir)
	
	if pos:
		var tex_pos = (size/2 + pos) / size
		var uv = Vector2(clamp(tex_pos.x, 0, 1), clamp(tex_pos.z, 0, 1))
		terrain.painter.brush = Cartographer.active_brush
		terrain.paint(action, uv)
		return true
	return false
