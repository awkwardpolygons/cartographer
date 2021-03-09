tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeCartoGetUV3D

func _init():
	set_default_input_values([1, 1.0])

func _get_name():
	return "GetUV3D"

func _get_category():
	return "Cartographer"

func _get_description():
	return "Get UV3D varying."

func _get_input_port_count():
	return 0

func _get_input_port_name(port):
	return null

func _get_input_port_type(port):
	return null

func _get_output_port_count():
	return 1

func _get_output_port_name(port):
	match port:
		0:
			return "uv3d"

func _get_output_port_type(port):
	match port:
		0:
			return PORT_TYPE_VECTOR

func _get_global_code(mode):
	return """
"""

func _get_code(input_vars, output_vars, mode, type):
	var io = {}
	for i in len(input_vars):
		io[_get_input_port_name(i) + "_in"] = input_vars[i]
	for i in len(output_vars):
		io[_get_output_port_name(i)] = output_vars[i]
	
	var tmpl = """// GetUV3D
{uv3d} = UV3D;
"""
	return tmpl.format(io)
