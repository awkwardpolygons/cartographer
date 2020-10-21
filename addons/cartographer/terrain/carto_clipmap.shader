shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

const float MESH_SIZE = 96.0;
const float MESH_STRIDE = 16.0;
uniform int INSTANCE_COUNT = 1;
uniform vec3 terrain_size;
uniform float terrain_diameter = 256;
uniform sampler2D hmap : hint_black;
varying vec3 UV3D;

vec3 clipmap(int id, vec3 cam, vec3 vtx, inout vec2 uv, inout vec4 clr) {
	// Divide terrain_size by 2 to get the bounds around center, in local space
	vec3 box = terrain_size / 2.0;
	// Get the surface num, stored in the y val, 0 for the inner surface, 1 for the outer
	int sfc = int(ceil(vtx.y));
	// Get the current starting instance level, based on the camera's height above the plane, in steps of 64
	int lvl = int(cam.y / 64.0);
	// Cap the lvl at the instance count
	lvl = min(lvl, INSTANCE_COUNT - 1);
	// Get the size mulitplier for each instance, each level is twice the size of the former
	float mul = pow(2.0, float(id));
	// cam is the camera offset, limit it to within the bounds of the terrain size
//	vec3 off = clamp(cam, terrain_diameter / 2.0 * -1.0, terrain_diameter / 2.0);
	vec3 off = clamp(cam, box * -1.0, box);
	// Set the stride, or number of units it moves per step,
	// which is the max quad size (16) so you don't get wavy terrain.
	off = floor(off / MESH_STRIDE) * MESH_STRIDE;
	// Double the size of the mesh so we have some overlap to clip as it moves
//	vtx *= 2.0;
	
	// Calculate the terrain uv
	uv = ((vtx.xz * mul + off.xz) / terrain_diameter) + 0.5;
//	uv = ((vtx.xz * mul) / 256.0) + 0.5;
	// Get the height from the heightmap
//	off.y = get_height(uv) * terrain_size.y;
	
	vtx = vtx * vec3(1, 0, 1) * mul + off;
	bool below = lvl + 1 - id > 0; // true if this vertex is on or below the first active level
	bool above = id + 1 - lvl > 0; // true if this vertex is on or above the first active level
	bool bound = !(abs(vtx.x) > box.x || abs(vtx.z) > box.z); // true if this vertex is within bounds
	bool clip = (bool(sfc) || below) && above && bound;
	
	clr = vec4(0.1 * float(id * 2 + sfc), 0, 0.1, 1);
//	vtx.y = 0.0;
//	return vtx * vec3(mul, 1.0 / float(clip), mul) + off;
	return vtx * vec3(1, 1.0 / float(clip), 1);
}

mat4 rotationY(float angle) {
	return mat4(vec4(cos(angle),	0,		sin(angle),	0),
		 		vec4(0,				1.0,	0,			0),
				vec4(-sin(angle),	0,		cos(angle),	0),
				vec4(0, 			0,		0,			1));
}

vec3 better_clipmap(int id, vec3 cam, vec3 vtx, inout vec2 uv, inout vec4 clr) {
//	float num = float(id);
//	// Divide terrain_size by 2 to get the bounds around center, in local space
//	vec3 box = terrain_size / 2.0;
//	// Get the surface num, stored in the y val, 0 for the inner surface, 1 for the outer
//	int sfc = int(ceil(vtx.y));
//	// Get the current starting instance level, based on the camera's height above the plane, in steps of 64
//	int lvl = int(cam.y / 64.0);
//	// Cap the lvl at the instance count
//	lvl = min(lvl, INSTANCE_COUNT - 1);
//	// Get the size mulitplier for each instance, each level is twice the size of the former
//	float mul = pow(2.0, float(id));
//	// cam is the camera offset, limit it to within the bounds of the terrain size
////	vec3 off = clamp(cam, terrain_diameter / 2.0 * -1.0, terrain_diameter / 2.0);
//	vec3 off = clamp(cam, box * -1.0, box);
//	// Set the stride, or number of units it moves per step,
//	// which is the max quad size (16) so you don't get wavy terrain.
//	off = floor(off / MESH_STRIDE) * MESH_STRIDE;
	id = id - 1;
	int sfc = int(ceil(vtx.y));
	float lvl = float(id / 4);
	float mul = pow(3.0, lvl);
	
	float rot = radians(float((id < 0 ? 0 : id) % 4) * 90.0);
	vec3 dir = (sfc == 0 ? vec3(1, 0, 1) : vec3(0, 0, 1));
	vec3 trn = dir * MESH_SIZE * mul * float(id < 0 ? 0 : 1);
	
	clr = vec4(trn / MESH_SIZE, 1);
	vtx = (vtx * mul + trn) * mat3(rotationY(rot));
	uv = ((vtx.xz * 1.0) / 2048.0) + 0.5;
	return vtx;
}

float get_height(vec2 uv) {
	vec4 h = texture(hmap, uv);
	return h.r;
}

vec3 calc_normal(vec2 uv, float _off) {
	vec3 off = vec2(_off, 0.0).xxy;
	float x = get_height(uv - off.xz) - get_height(uv + off.xz);
	float y = get_height(uv - off.zy) - get_height(uv + off.zy);
	return normalize(vec3(x, off.x * 8.0, y));
}

void vertex() {
	VERTEX = better_clipmap(INSTANCE_ID, CAMERA_MATRIX[3].xyz, VERTEX, UV, COLOR);
	float h = get_height(UV);
	vec3 n = calc_normal(UV, 1.0 / 2048.0);
	VERTEX.y = 0.0;
	VERTEX.y = h * 512.0;
	NORMAL = n;
//	VERTEX.y += 10.0;
//	VERTEX = vec3(VERTEX);
}

void fragment() {
	vec3 n = calc_normal(UV, 1.0 / 2048.0);
	NORMAL = (vec4(n.xyz, 1) * CAMERA_MATRIX).xyz;
	ALBEDO = COLOR.rgb;
}
