tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeCartoTangentSpace

func _init():
	set_default_input_values([0, Vector3(0, 1, 0)])

func _get_name():
	return "TangentSpace"

func _get_category():
	return "Cartographer"

func _get_description():
	return "Get Tangent and Binormal from Normal input."

func _get_input_port_count():
	return 1

func _get_input_port_name(port):
	match port:
		0:
			return "normal"

func _get_input_port_type(port):
	match port:
		0:
			return PORT_TYPE_VECTOR

func _get_output_port_count():
	return 3

func _get_output_port_name(port):
	match port:
		0:
			return "normal"
		1:
			return "tangent"
		2:
			return "binormal"

func _get_output_port_type(port):
	match port:
		0:
			return PORT_TYPE_VECTOR
		1:
			return PORT_TYPE_VECTOR
		2:
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
	
	var tmpl = """// TangentSpace
{normal} = {normal_in};
{tangent} = vec3(0.0,0.0,-1.0) * ({normal}.x);
{tangent} += vec3(1.0,0.0,0.0) * ({normal}.y);
{tangent} += vec3(1.0,0.0,0.0) * ({normal}.z);
{tangent} = normalize({tangent});
{binormal} = vec3(0.0,-1.0,0.0) * abs({normal}.x);
{binormal} += vec3(0.0,0.0,-1.0) * abs({normal}.y);
{binormal} += vec3(0.0,-1.0,0.0) * abs({normal}.z);
{binormal} = normalize({binormal});
"""
	return tmpl.format(io)
