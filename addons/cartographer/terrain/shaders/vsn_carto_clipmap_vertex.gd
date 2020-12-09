tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeCartoClipmapVertex

func _get_name():
	return "ClipmapVertex"

func _get_category():
	return "Cartographer"

func _get_description():
	return "Clipmap vertex transform node."

func _get_input_port_count():
	return 0

func _get_input_port_name(port):
	match port:
		0:
			return "height"
		1:
			return "normal"

func _get_input_port_type(port):
	match port:
		0:
			return PORT_TYPE_SCALAR
		1:
			return PORT_TYPE_VECTOR

func _get_output_port_count():
	return 4

func _get_output_port_name(port):
	match port:
		0:
			return "vertex"
		1:
			return "uv"
		2:
			return "uv2"
		3:
			return "uv3d"

func _get_output_port_type(port):
	match port:
		0:
			return PORT_TYPE_VECTOR
		1:
			return PORT_TYPE_VECTOR
		2:
			return PORT_TYPE_VECTOR
		3:
			return PORT_TYPE_VECTOR

func _get_global_code(mode):
	return """// Clipmap globals
const float MESH_SIZE = 128.0;
const float MESH_STRIDE = 27.0;
uniform int INSTANCE_COUNT = 1;
uniform vec3 clipmap_size;
uniform float clipmap_diameter = 256;
varying vec3 UV3D;

vec3 clipmap(int idx, vec3 cam, vec3 vtx, inout vec3 uv, inout vec3 clr) {
	int sfc = int(ceil(vtx.y));
	vec3 box = vec3(clipmap_diameter) / 2.0;
	vec3 off = clamp(cam, -box, box);
//	off = vec3(0);
	off = trunc(off / MESH_STRIDE) * MESH_STRIDE;
	vtx.xz += off.xz;
	uv = vec3((vtx.xz / clipmap_diameter) + 0.5, 0);
	
//	vec3 lim = clipmap_size / 2.0;
//	vtx *= 1.0 / (abs(vtx.x) > lim.x || abs(vtx.z) > lim.z ? 0.0 : 1.0);
	clr = (sfc == 0 ? vec3(1, 0, 1) : vec3(0, 0, 1));
	return vtx;
}
"""

func _get_code(input_vars, output_vars, mode, type):
	var io = {}
	for i in len(input_vars):
		io[_get_input_port_name(i) + "_in"] = input_vars[i]
	for i in len(output_vars):
		io[_get_output_port_name(i)] = output_vars[i]
	
	var tmpl = """// Clipmap
vec3 color = COLOR.rgb;
{uv} = vec3(UV, 0);
{vertex} = VERTEX;
{vertex} = (WORLD_MATRIX * vec4({vertex}, 1)).xyz;
{vertex} = clipmap(INSTANCE_ID, CAMERA_MATRIX[3].xyz, {vertex}, {uv}, color);
{vertex}.y = 0.0;

{uv2} = {uv};
UV3D = {vertex};
UV3D.xz += 0.5 * clipmap_diameter;
{uv3d} = UV3D;
//	UV3D = UV3D * uv1_scale.xzy + uv1_offset.xzy;
{uv} = vec3(UV3D.xz, 0);
"""
	return tmpl.format(io)
