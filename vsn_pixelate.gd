tool
extends VisualShaderNodeCustom
class_name VisualShaderNodePixelate

func _get_name():
	return "Pixelate"

func _get_category():
	return "Textures"

func _get_description():
	return "Pixelate a texture."

func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_SCALAR

func _get_input_port_count():
	return 3

func _get_input_port_name(port):
	match port:
		0:
			return "factor"
		1:
			return "uv"
		2:
			return "sampler"

func _get_input_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR
		1:
			return VisualShaderNode.PORT_TYPE_VECTOR
		2:
			return VisualShaderNode.PORT_TYPE_SAMPLER

func _get_output_port_count():
	return 2

func _get_output_port_name(port):
	match port:
		0:
			return "rgb"
		1:
			return "a"

func _get_output_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR
		1:
			return VisualShaderNode.PORT_TYPE_SCALAR

func _get_global_code(mode):
	return """
vec4 pixelate(sampler2D sampler, vec2 uv, vec2 factor) {
	vec2 xy = vec2(textureSize(sampler, 0)) * uv;
	xy = xy - mod(xy, factor) + factor / vec2(2, 2);
	return texelFetch(sampler, ivec2(round(xy)), 0);
}
"""

func _get_code(input_vars, output_vars, mode, type):
	return """
vec4 px = pixelate(%s, %s.xy, %s.xy);
%s = px.rgb;
%s = px.a;
""" % [input_vars[2], input_vars[1], input_vars[0], output_vars[0], output_vars[1]]
