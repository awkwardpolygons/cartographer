tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeCartoHeightmapCalc

func _get_name():
	return "HeightmapCalc"

func _get_category():
	return "Cartographer"

func _get_description():
	return "Clipmap vertex transform node."

func _get_input_port_count():
	return 2

func _get_input_port_name(port):
	match port:
		0:
			return "heightmap"
		1:
			return "uv"

func _get_input_port_type(port):
	match port:
		0:
			return PORT_TYPE_SAMPLER
		1:
			return PORT_TYPE_VECTOR

func _get_output_port_count():
	return 2

func _get_output_port_name(port):
	match port:
		0:
			return "height"
		1:
			return "normal"

func _get_output_port_type(port):
	match port:
		0:
			return PORT_TYPE_SCALAR
		1:
			return PORT_TYPE_VECTOR

func _get_global_code(mode):
	return """// HeightmapCalc globals
float get_height(sampler2D hmap, vec2 uv) {
	vec4 h = texture(hmap, uv);
	h = uv.x > 1.0 || uv.y > 1.0 ? vec4(0) : h;
	h = uv.x < 0.0 || uv.y < 0.0 ? vec4(0) : h;
	return h.r;
}

vec3 calc_normal(sampler2D hmap, vec2 uv, float _off) {
	vec3 off = vec2(_off, 0.0).xxy;
	float x = get_height(hmap, uv - off.xz) - get_height(hmap, uv + off.xz);
	float y = get_height(hmap, uv - off.zy) - get_height(hmap, uv + off.zy);
	return normalize(vec3(x, off.x * 8.0, y));
}
"""

func _get_code(input_vars, output_vars, mode, type):
	var io = {}
	for i in len(input_vars):
		io[_get_input_port_name(i) + "_in"] = input_vars[i]
	for i in len(output_vars):
		io[_get_output_port_name(i)] = output_vars[i]
	
	var tmpl = """// HeightmapCalc
{height} = get_height({heightmap_in}, {uv_in}.xy);
{normal} = calc_normal({heightmap_in}, {uv_in}.xy, 1.0/2048.0);
"""
	return tmpl.format(io)
