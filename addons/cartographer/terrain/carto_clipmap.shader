shader_type spatial;
render_mode skip_vertex_transform,blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

const float MESH_SIZE = 128.0;
const float MESH_STRIDE = 27.0;
uniform int INSTANCE_COUNT = 1;
uniform vec3 terrain_size;
uniform float terrain_diameter = 256;
uniform sampler2D heightmap : hint_black;
varying vec3 UV3D;

vec3 better_clipmap(int idx, vec3 cam, vec3 vtx, inout vec2 uv, inout vec4 clr) {
	int sfc = int(ceil(vtx.y));
	vec3 box = vec3(terrain_diameter) / 2.0;
	vec3 off = clamp(cam, -box, box);
//	off = vec3(0);
	off = trunc(off / MESH_STRIDE) * MESH_STRIDE;
	vtx.xz += off.xz;
	uv = (vtx.xz / terrain_diameter) + 0.5;
	
//	vec3 lim = terrain_size / 2.0;
//	vtx *= 1.0 / (abs(vtx.x) > lim.x || abs(vtx.z) > lim.z ? 0.0 : 1.0);
	clr = vec4((sfc == 0 ? vec3(1, 0, 1) : vec3(0, 0, 1)), 1);
	return vtx;
}

float get_height(vec2 uv) {
	vec4 h = texture(heightmap, uv);
	h = uv.x > 1.0 || uv.y > 1.0 ? vec4(0) : h;
	h = uv.x < 0.0 || uv.y < 0.0 ? vec4(0) : h;
	return h.r;
}

vec3 calc_normal(vec2 uv, float _off) {
	vec3 off = vec2(_off, 0.0).xxy;
	float x = get_height(uv - off.xz) - get_height(uv + off.xz);
	float y = get_height(uv - off.zy) - get_height(uv + off.zy);
	return normalize(vec3(x, off.x * 8.0, y));
}

void vertex() {
	vec3 vtx = VERTEX;
	vtx = (WORLD_MATRIX * vec4(vtx, 1)).xyz;
	VERTEX = better_clipmap(INSTANCE_ID, CAMERA_MATRIX[3].xyz, vtx, UV, COLOR);
	
	UV2 = UV;
	UV3D = VERTEX;
	UV3D.xz += 0.5 * terrain_diameter;
//	UV3D = UV3D * uv1_scale.xzy + uv1_offset.xzy;
	UV = UV3D.xz;
	
//	UV = (vtx.xz / 1024.0) + 0.5;
	float h = get_height(UV2);
	vec3 n = calc_normal(UV2, 1.0 / 2048.0);
	VERTEX.y = 0.0;
	VERTEX.y = h * terrain_size.y;
	NORMAL = n;
//	VERTEX.y += 10.0;
//	VERTEX = vec3(VERTEX);
	
	TANGENT = vec3(0.0,0.0,-1.0) * (NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * (NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * (NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,-1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,-1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	NORMAL = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	BINORMAL = (MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz;
	TANGENT = (MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz;
	VERTEX = (INV_CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = calc_normal(UV2, 1.0 / 2048.0);
	NORMAL = (vec4(n.xyz, 1) * CAMERA_MATRIX).xyz;
	ALBEDO = COLOR.rgb;
}
