shader_type spatial;
render_mode skip_vertex_transform,blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

const float CALC_NORM_OFF = 1.0/2048.0;
//const float MESH_SIZE = 81.0;
const float MESH_SIZE = 128.0;
//const float MESH_STRIDE = 27.0;
const float MESH_STRIDE = 32.0;
uniform int INSTANCE_COUNT = 1;
uniform vec3 clipmap_size;
uniform float clipmap_diameter = 256;
uniform sampler2D heightmap : hint_black;
uniform vec3 origin;
varying vec3 UV3D;
varying vec3 MEGA_UV3D;

uniform sampler2D h1 : hint_black;
uniform sampler2D h2 : hint_black;
uniform sampler2D h3 : hint_black;
uniform sampler2D w1 : hint_black;
uniform sampler2D w2 : hint_black;
uniform sampler2D w3 : hint_black;
uniform sampler2D w4 : hint_black;
uniform sampler2D w5 : hint_black;
uniform sampler2DArray heightmap_arr;

vec3 better_clipmap(int idx, vec3 cam, vec3 vtx, vec3 org, inout vec2 uv, inout vec3 muv, inout vec4 clr) {
	int sfc = int(ceil(vtx.y));
	vec3 box = vec3(clipmap_diameter) / 2.0;
	vec3 off = cam;
//	vec3 off = clamp(cam - origin, -box, box);
	off = vec3(0);
//	off = trunc(off / MESH_STRIDE) * MESH_STRIDE;
	muv = vtx - org;
	vtx.xz += off.xz;
	uv = ((vtx.xz - org.xz) / clipmap_diameter) + 0.5;
	
	vec3 lim = clipmap_size / 2.0;
//	vtx *= 1.0 / (abs(vtx.x - org.x) >= lim.x + 0.5 || abs(vtx.z - org.z) >= lim.z + 0.5 ? 0.0 : 1.0);
	clr = vec4((sfc == 0 ? vec3(1, 0, 1) : vec3(0, 0, 1)), 1);
	return vtx;
}

float get_height(sampler2D hmap, vec2 uv) {
	vec4 h = texture(hmap, uv);
//	vec4 h = texelFetch(hmap, ivec2(uv), 0);
//	float idx = float((int(uv.x) + 1) * (int(uv.y) + 1) - 1);
//	uv = mod(uv, vec2(1));
//	vec4 h = texture(heightmap_arr, vec3(uv, idx));
	
//	h = uv.x > 1.0 || uv.y > 1.0 ? vec4(0) : h;
//	h = uv.x < 0.0 || uv.y < 0.0 ? vec4(0) : h;
	return h.r;
}

vec3 calc_normal(sampler2D hmap, vec2 uv, float _off) {
	vec3 off = vec2(_off, 0.0).xxy;
	float x = get_height(hmap, uv - off.xz) - get_height(hmap, uv + off.xz);
	float y = get_height(hmap, uv - off.zy) - get_height(hmap, uv + off.zy);
	return normalize(vec3(x, off.x * 8.0, y));
}

float calc_terrain(sampler2D hmap, vec2 uv, inout vec3 nrm) {
	float h = get_height(hmap, uv);
	vec3 n = calc_normal(hmap, uv, CALC_NORM_OFF);
	nrm = n;
	return h;
}

void vertex() {
	vec3 vtx = VERTEX;
	vtx = (WORLD_MATRIX * vec4(vtx, 1)).xyz;
	vec3 org = WORLD_MATRIX[3].xyz;
//	org = origin;
	vec3 cam = CAMERA_MATRIX[3].xyz - org;
	VERTEX = better_clipmap(INSTANCE_ID, cam, vtx, org, UV, MEGA_UV3D, COLOR);
//	COLOR = vec4(org / clipmap_diameter, 1);
	
	UV2 = UV;
	UV3D = VERTEX;
//	UV3D.xz += 0.5 * clipmap_diameter;
//	UV3D = UV3D * uv1_scale.xzy + uv1_offset.xzy;
	UV = UV3D.xz;
//	COLOR = vec4(UV2, 0.0, 0.0);
//	COLOR = WORLD_MATRIX[3].rgba;
	
//	UV = (vtx.xz / 1024.0) + 0.5;
//	UV2.x = org.x > 0.0 ? UV2.x + 0.5 : UV2.x - 0.5;
//	UV2.x = org.x > 0.0 ? UV2.x + 1.0 : UV2.x;
//	UV2.y = org.z > 0.0 ? UV2.y + 1.0 : UV2.y;
	
	float h = 0.0;
	vec3 n = vec3(0, 1, 0);
//	vec2 uv = UV;
	vec2 uv = MEGA_UV3D.xz;
	
	float res = 1500.0;
	if (uv.x > -res/2.0 && uv.y > -res/2.0 && uv.x < res/2.0 && uv.y < res/2.0) {
		uv += res/2.0;
		uv /= res;
		h = get_height(h1, uv);
		n = calc_normal(h1, uv, 1.0 / 2048.0);
	}
	else if (uv.x > -res && uv.y > -res && uv.x < res && uv.y < res) {
		uv += res;
//		uv /= 2.0;
		uv /= res * 2.0;
		h = get_height(h2, uv);
		n = calc_normal(h2, uv, 1.0 / 2048.0);
	}
	else if (uv.x > -res*2.0 && uv.y > -res*2.0 && uv.x < res*2.0 && uv.y < res*2.0) {
		uv += res * 2.0;
//		uv /= 4.0;
		uv /= res * 4.0;
		h = get_height(h3, uv);
		n = calc_normal(h3, uv, 1.0 / 2048.0);
	}
	
//	uv += 2048.0 * 2.0;
//	h = get_height(heightmap, uv / 16384.0);
//	n = calc_normal(heightmap, uv, CALC_NORM_OFF);
	VERTEX.y = 0.0;
	VERTEX.y = h * clipmap_size.y;
	NORMAL = n;
	
//	VERTEX.y = calc_terrain(heightmap, (UV + 2048.0) / 4096.0, NORMAL) * clipmap_size.y;
	
//	vec2 uv = UV2 * 3.0;
////	uv = mod(uv, vec2(1));
//	float h = get_height(heightmap, uv);
//	vec3 n = calc_normal(heightmap, uv, 1.0 / 2048.0);
//	VERTEX.y = 0.0;
//	VERTEX.y = h * clipmap_size.y;
//	NORMAL = n;
	
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
	NORMAL = (INV_CAMERA_MATRIX * vec4(NORMAL, 0.0)).xyz;
	BINORMAL = (INV_CAMERA_MATRIX * vec4(BINORMAL, 0.0)).xyz;
	TANGENT = (INV_CAMERA_MATRIX * vec4(TANGENT, 0.0)).xyz;
	VERTEX = (INV_CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
//	vec3 n = calc_normal(UV2, 1.0 / 2048.0);
//	NORMAL = (vec4(n.xyz, 1) * CAMERA_MATRIX).xyz;
	ALBEDO = COLOR.rgb;
//	ALBEDO = texture(heightmap, UV2).rgb;
//	vec2 uv = UV - clipmap_diameter/2.0 - CAMERA_MATRIX[3].xz;
//	if (uv.x < 1024.0 && uv.x > -1024.0 && uv.y < 1024.0 && uv.y > -1024.0) {
//		ALBEDO = texture(t1, uv / 2048.0).rgb;
//	} else if (uv.x < 3072.0 && uv.x > -3072.0 && uv.y < 3072.0 && uv.y > -3072.0) {
//		ALBEDO = texture(t2, uv / 6144.0).rgb;
//	}
	
	vec4 c = vec4(0);
	vec3 n = vec3(0, 1, 0);
//	vec2 uv = UV;
	vec2 uv = MEGA_UV3D.xz;
	float res = 1500.0;
	if (uv.x > -res/2.0 && uv.y > -res/2.0 && uv.x < res/2.0 && uv.y < res/2.0) {
		uv += res/2.0;
		uv /= res;
		c = texture(w1, uv);
		c *= vec4(2, 1, 1, 1);
		c *= COLOR;
//		n = calc_normal(h1, uv, 1.0 / 2048.0);
	}
	else if (uv.x > -res && uv.y > -res && uv.x < res && uv.y < res) {
		uv += res;
		uv /= res * 2.0;
		c = texture(w2, uv);
		c *= vec4(1, 2, 1, 1);
		c *= COLOR;
//		n = calc_normal(h2, uv, 1.0 / 2048.0);
	}
	else if (uv.x > -res*2.0 && uv.y > -res*2.0 && uv.x < res*2.0 && uv.y < res*2.0) {
		uv += res * 2.0;
		uv /= res * 4.0;
		c = texture(w3, uv);
		c *= vec4(1, 1, 2, 1);
		c *= COLOR;
//		n = calc_normal(h3, uv, 1.0 / 2048.0);
	}
//	else if (uv.x > -res*8.0 && uv.y > -res*8.0 && uv.x < res*8.0 && uv.y < res*8.0) {
//		uv += res * 8.0;
//		uv /= res * 16.0;
//		c = texture(w4, uv);
//		c *= vec4(2, 1, 1, 1);
////		n = calc_normal(h3, uv, 1.0 / 2048.0);
//	}
//	else if (uv.x > -res*32.0 && uv.y > -res*32.0 && uv.x < res*32.0 && uv.y < res*32.0) {
//		uv += res * 32.0;
//		uv /= res * 64.0;
//		c = texture(w5, uv);
//		c *= vec4(1, 2, 1, 1);
////		n = calc_normal(h3, uv, 1.0 / 2048.0);
//	}
	NORMAL = (vec4(n.xyz, 1) * CAMERA_MATRIX).xyz;
	ALBEDO = c.rgb;
}
