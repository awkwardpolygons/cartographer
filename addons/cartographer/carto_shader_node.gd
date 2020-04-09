tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeCartoTerrain

func _get_name():
	return "CartoTerrain"

func _get_category():
	return "Cartographer"

func _get_description():
	return "Cartographer terrain custom node"

func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_SCALAR

func _get_input_port_count():
	return 2

func _get_input_port_name(port):
	match port:
		0:
			return "uv"
		1:
			return "index"

func _get_input_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR
		1:
			return VisualShaderNode.PORT_TYPE_SCALAR

func _get_output_port_count():
	return 1

func _get_output_port_name(port):
	return "texture"

func _get_output_port_type(port):
	return VisualShaderNode.PORT_TYPE_VECTOR

func _get_global_code(mode):
	return """
uniform sampler2DArray layers;
"""

func _get_code(input_vars, output_vars, mode, type):
	print(input_vars[0])
	input_vars[0] = "UV" if !input_vars[0] else input_vars[0]
	return output_vars[0] + " = texture(layers, vec3(%s.xy, %s)).rgb" % input_vars
