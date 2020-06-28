tool
extends EditorPlugin

const Action = Cartographer.Action
const BrushesPanel = preload("res://addons/cartographer/brushes_panel/brushes_panel.tscn")
const Toolbar = preload("res://addons/cartographer/toolbar/cartographer_toolbar.tscn")

var _action = Action.NONE
var brushes_panel = BrushesPanel.instance()
var toolbar = Toolbar.instance()
var editor = get_editor_interface()
var terrain: CartoTerrain
var do_paint: bool = false
var inspector_plugin: CartoTerrainInspector

func _init():
	add_autoload_singleton("Cartographer", "res://addons/cartographer/cartographer_singleton.gd")
	inspector_plugin = CartoTerrainInspector.new()
	add_inspector_plugin(inspector_plugin)

func _enter_tree():
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, brushes_panel)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
	toolbar.visible = false
	Cartographer.editor = editor
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
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
	if brushes_panel:
		brushes_panel.free()
	if toolbar:
		toolbar.free()

func save_external_data():
	Cartographer.save()

func get_plugin_name():
	return "Cartographer"

# TODO: Investigate MultiNodeEdit
func handles(obj: Object):
#	print("handles ", obj)
	if obj is CartoTerrain:
		return true
#	edit(null)
	return false

func get_terrain_from(obj: Object):
	if obj is EditorSelection:
		obj = obj.get_selected_nodes()[0]
	if obj is CartoTerrain:
		return obj
	return null

func edit(obj: Object):
	terrain = get_terrain_from(obj)

func make_visible(visible):
	toolbar.visible = visible

func forward_spatial_gui_input(camera, event):
	var action = get_action(event)
#	prints("-->", action, Cartographer.get_action())
#	return true
	return try_paint(camera, action)

func get_action(event):
	var action = Cartographer.get_action(event.alt)
	_action &= ~Action.JUST_CHANGED
	var prev = _action
	
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			_action = action | Action.ON
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		_action = action | (Action.ON if event.pressed else 0)
	elif event is InputEventKey and event.scancode == KEY_BACKSPACE:
		_action = Action.CLEAR | (Action.ON if event.is_pressed() else 0)
	if prev != _action:
		_action |= Action.JUST_CHANGED
	return _action

func try_paint(camera, action):
	var is_on = action & Action.ON > 0
	if not Cartographer.active_brush:
		if is_on:
			push_warning("Select a brush before painting or sculpting")
		return false
	if !is_on:
		terrain.paint(action, Vector2(-1, -1))
		return false
	
	var viewport = camera.get_viewport()
	var viewport_container = viewport.get_parent()
	var screen_pos = viewport.get_mouse_position() * viewport.size / viewport_container.rect_size
	
#	var size = Vector3(terrain.size.x, 0, terrain.size.z)
	var size = Vector3(terrain.diameter, 0, terrain.diameter)
	var org = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	var pos = terrain.intersect_ray(org, dir)
	
	if pos:
		var tex_pos = (size/2 + pos) / size
		var uv = Vector2(clamp(tex_pos.x, 0, 1), clamp(tex_pos.z, 0, 1))
		terrain.paint(action, uv)
		return is_on
	return false
