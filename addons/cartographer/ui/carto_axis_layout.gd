tool
extends Container
class_name CartoAxisLayout

enum Direction {VERTICAL, HORIZONTAL}
export(Direction) var direction setget _set_direction
export var spacing = 0 setget _set_spacing

var pad_primary_start = 0 setget _set_pad_primary_start
var pad_primary_end = 0 setget _set_pad_primary_end
var pad_secondary_start = 0 setget _set_pad_secondary_start
var pad_secondary_end = 0 setget _set_pad_secondary_end

func _set_direction(v):
#	rect_min_size = Vector2(0, 0)
	direction = v
	queue_sort()

func _set_spacing(v):
	spacing = v
	queue_sort()

func _set_pad_primary_start(v):
	pad_primary_start = v
	queue_sort()

func _set_pad_primary_end(v):
	pad_primary_end = v
	queue_sort()

func _set_pad_secondary_start(v):
	pad_secondary_start = v
	queue_sort()

func _set_pad_secondary_end(v):
	pad_secondary_end = v
	queue_sort()

func get_primary_axis():
	return "y" if direction == Direction.VERTICAL else "x"

func get_secondary_axis():
	return "x" if direction == Direction.VERTICAL else "y"

func _get_property_list():
	var properties = []
	properties.append({
		name = "Padding",
		type = TYPE_NIL,
		hint_string = "pad_",
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	var obj = {
		name = "pad_primary_start",
		type = TYPE_INT,
		usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
	}
	properties.append(obj)
	obj = obj.duplicate()
	obj.name = "pad_primary_end"
	properties.append(obj)
	obj = obj.duplicate()
	obj.name = "pad_secondary_start"
	properties.append(obj)
	obj = obj.duplicate()
	obj.name = "pad_secondary_end"
	properties.append(obj)
	return properties

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_do_layout()

func _do_layout():
	var pri_len = pad_primary_start
	var sec_off = pad_secondary_start
	var pri_axis = get_primary_axis()
	var sec_axis = get_secondary_axis()
	var pos: Vector2
	var rect: Rect2
	var size = Vector2(0, 0)
	
	for ch in get_children():
		if !ch.visible or ch is Popup:
			continue
		
		size = ch.get_combined_minimum_size()
		size[sec_axis] = rect_size[sec_axis] - (pad_secondary_start + pad_secondary_end)
		size[pri_axis] = size[sec_axis]
		
		pos[pri_axis] = pri_len
		pos[sec_axis] = sec_off
		rect = Rect2(pos, size)
		
		fit_child_in_rect(ch, rect)
		if ch.has_method("get_combined_minimum_size"):
			size = ch.get_combined_minimum_size()
			rect.size = size
			fit_child_in_rect(ch, rect)
		pri_len += size[pri_axis] + spacing
	
#	rect_size[pri_axis] = pri_len - spacing + pad_primary_end
#	rect_size[sec_axis] = size[sec_axis] + pad_secondary_start + pad_secondary_end
	var a = rect_min_size
	a[pri_axis] = pri_len - spacing + pad_primary_end
	rect_min_size = a
	var b = rect_size
	b[sec_axis] = size[sec_axis] + pad_secondary_start + pad_secondary_end
	rect_size = b

func get_combined_minimum_size() -> Vector2:
	var size = .get_combined_minimum_size()
	size.x = max(rect_size.x, size.x)
	size.y = max(rect_size.y, size.x)
	return size
