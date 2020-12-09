tool
extends VisualShader
class_name CartoClipmapVisualShader

enum {OUTPUT_ID = 0, GLOBAL_ID = 3, CLIPMAP_ID, TRANSFORMS_ID}
var global: VisualShaderNodeGlobalExpression
var clipmap: VisualShaderNodeExpression

func _init():
	set("flags/skip_vertex_transform", true)
	
	global = VisualShaderNodeGlobalExpression.new()
	global.expression = global_tmpl()
	
	clipmap = VisualShaderNodeExpression.new()
	clipmap.add_input_port(0, VisualShaderNodeExpression.PORT_TYPE_SAMPLER, "heightmap")
	clipmap.add_output_port(0, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "vertex")
	clipmap.add_output_port(1, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "normal")
	clipmap.add_output_port(2, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "tangent")
	clipmap.add_output_port(3, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "binormal")
	clipmap.add_output_port(4, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "uv")
	clipmap.add_output_port(5, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "color")
	clipmap.expression = clipmap_tmpl()
	
	var transforms = VisualShaderNodeExpression.new()
	transforms.add_input_port(0, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "vertex")
	transforms.add_input_port(1, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "normal")
	transforms.add_input_port(2, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "tangent")
	transforms.add_input_port(3, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "binormal")
	transforms.add_output_port(0, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "vertex_x")
	transforms.add_output_port(1, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "normal_x")
	transforms.add_output_port(2, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "tangent_x")
	transforms.add_output_port(3, VisualShaderNodeExpression.PORT_TYPE_VECTOR, "binormal_x")
	transforms.expression = transforms_tmpl()
	
	add_node(VisualShader.TYPE_VERTEX, global, Vector2(0, -128), GLOBAL_ID)
	add_node(VisualShader.TYPE_VERTEX, clipmap, Vector2(-768, 0), CLIPMAP_ID)
	add_node(VisualShader.TYPE_VERTEX, transforms, Vector2(-128, 0), TRANSFORMS_ID)
	connect_nodes(VisualShader.TYPE_VERTEX, CLIPMAP_ID, 0, TRANSFORMS_ID, 0)
	connect_nodes(VisualShader.TYPE_VERTEX, CLIPMAP_ID, 1, TRANSFORMS_ID, 1)
	connect_nodes(VisualShader.TYPE_VERTEX, CLIPMAP_ID, 2, TRANSFORMS_ID, 2)
	connect_nodes(VisualShader.TYPE_VERTEX, CLIPMAP_ID, 3, TRANSFORMS_ID, 3)
	connect_nodes(VisualShader.TYPE_VERTEX, TRANSFORMS_ID, 0, OUTPUT_ID, 0)
	connect_nodes(VisualShader.TYPE_VERTEX, TRANSFORMS_ID, 1, OUTPUT_ID, 1)
	connect_nodes(VisualShader.TYPE_VERTEX, TRANSFORMS_ID, 2, OUTPUT_ID, 2)
	connect_nodes(VisualShader.TYPE_VERTEX, TRANSFORMS_ID, 3, OUTPUT_ID, 3)
	connect_nodes(VisualShader.TYPE_VERTEX, CLIPMAP_ID, 4, OUTPUT_ID, 4)
	connect_nodes(VisualShader.TYPE_VERTEX, CLIPMAP_ID, 5, OUTPUT_ID, 6)

func global_tmpl():
	return """// Clipmap globals
const float MESH_SIZE = 128.0;
const float MESH_STRIDE = 27.0;
uniform int INSTANCE_COUNT = 1;
uniform vec3 clipmap_size;
uniform float clipmap_diameter = 256;
//uniform sampler2D heightmap : hint_black;
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

func clipmap_tmpl():
	return """// Clipmap
color = COLOR.rgb;
uv = vec3(UV, 0);
vertex = VERTEX;
vertex = (WORLD_MATRIX * vec4(vertex, 1)).xyz;
vertex = clipmap(INSTANCE_ID, CAMERA_MATRIX[3].xyz, vertex, uv, color);
vertex.y = 0.0;

vec4 h = texture(heightmap, uv.xy);
h = uv.x > 1.0 || uv.y > 1.0 ? vec4(0) : h;
h = uv.x < 0.0 || uv.y < 0.0 ? vec4(0) : h;

vertex.y = h.r;

normal = vec3(0, 1, 0);
tangent = vec3(0.0,0.0,-1.0) * (normal.x);
tangent+= vec3(1.0,0.0,0.0) * (normal.y);
tangent+= vec3(1.0,0.0,0.0) * (normal.z);
tangent = normalize(tangent);
binormal = vec3(0.0,-1.0,0.0) * abs(normal.x);
binormal+= vec3(0.0,0.0,-1.0) * abs(normal.y);
binormal+= vec3(0.0,-1.0,0.0) * abs(normal.z);
binormal = normalize(binormal);
"""

func transforms_tmpl():
	return """// Clipmap transforms
normal_x = (MODELVIEW_MATRIX * vec4(normal, 0.0)).xyz;
binormal_x = (MODELVIEW_MATRIX * vec4(binormal, 0.0)).xyz;
tangent_x = (MODELVIEW_MATRIX * vec4(tangent, 0.0)).xyz;
vertex_x = (INV_CAMERA_MATRIX * vec4(vertex, 1.0)).xyz;
"""
