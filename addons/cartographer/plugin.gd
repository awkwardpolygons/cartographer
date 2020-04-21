tool
extends EditorPlugin

var dock
var editor = get_editor_interface()
var terrain: CartoTerrain
var brush: CartoBrush
var do_paint: bool = false

enum {NONE, PAINT, ERASE, CLEAR}


func _enter_tree():
	editor.get_selection().connect("selection_changed", self, "_on_selection_changed", [dock])

func _on_selection_changed(dock):
	var selected = editor.get_selection().get_selected_nodes()
#	print("selected ", selected)
	if len(selected) == 0:
		handles(null)

func _exit_tree():
	pass

# TODO: Investigate MultiNodeEdit
func handles(obj: Object):
#	print("handles ", obj)
	if obj is CartoBrush or obj is CartoTerrain:
		return true
	edit(null)
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
	print("EDIT", obj)
	terrain = get_terrain_from(obj)
	brush = get_brush_from(obj)

func make_visible(visible):
	pass

func forward_spatial_gui_input(camera, event):
	var action = get_action(event)
	if action == CLEAR:
		terrain.painter.clear()
		return false
	return try_paint(camera, action) or action

func get_action(event):
	var action = NONE
	if event is InputEventMouseMotion:
		action = PAINT if Input.is_mouse_button_pressed(BUTTON_LEFT) else NONE
		action = ERASE if action and event.alt else action
	if event is InputEventKey and event.scancode == KEY_BACKSPACE:
		action = CLEAR
	return action

func try_paint(camera, action):
	if action == NONE:
		return false
	var viewport = camera.get_viewport()
	var viewport_container = viewport.get_parent()
	var screen_pos = viewport.get_mouse_position() * viewport.size / viewport_container.rect_size
	
	var size = Vector3(terrain.size.x, 0, terrain.size.y)
	var org = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	var pos = raycast(org, dir)
	
	if pos:
		var tex_pos = (size/2 + pos) / size
		var uv = Vector2(clamp(tex_pos.x, 0, 1), clamp(tex_pos.z, 0, 1))
		terrain.painter.paint(uv, Color(1, 0, 0, 1))
		return true
	return false

func raycast(origin: Vector3, direction: Vector3):
	var space_state = terrain.get_world().direct_space_state
	var result = space_state.intersect_ray(origin, direction * 800)
	return result.get("position")
