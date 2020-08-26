shader_type spatial;
render_mode cull_disabled;

const float MESH_STRIDE = 16.0;
const int NUM_LAYERS = 16;
const float MASK_SCALE = 2.0;
uniform int INSTANCE_COUNT = 1;
uniform sampler2D terrain_height : hint_black;
uniform sampler2D terrain_masks : hint_black;
uniform sampler2DArray terrain_textures : hint_albedo;
uniform vec3 terrain_size;
uniform float terrain_diameter = 256;
uniform vec2 uv1_scale = vec2(1);
uniform uint use_triplanar = 0;
uniform float is_editing = 0.0;
uniform vec2 brush_pos;
uniform float brush_scale = 0.1;
varying vec3 position;
varying vec3 normal;

float get_height(vec2 uv) {
	vec4 h = texture(terrain_height, uv);
	return h.r;
}

// TODO: Fix the ground level being 0 rather than the height at cam position.
vec3 clip_map(int id, vec3 cam, vec3 vtx, inout vec2 uv, inout vec4 clr) {
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
	off.y = get_height(uv) * terrain_size.y;
	
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

vec3 calc_normal(vec2 uv, float rng) {
	// TODO: Modify this gradient step resolution based on the density of the mesh,
	// vertices closer together use smaller steps to calc normal, vertices further
	// apart use larger steps.
//	vec3 e = vec2(1.0 / terrain_diameter, 0.0).xxy;
//	vec3 e = vec2(1.0 / terrain_diameter / float(rng), 0.0).xxy;
	vec3 e = vec2(rng / terrain_diameter, 0.0).xxy;
//	vec3 e = vec2(clamp(rng / terrain_diameter * 0.01, 1.0 / terrain_diameter, terrain_diameter), 0.0).xxy;
//	float x = h - get_height(uv + e.xz);
//	float y = h - get_height(uv + e.zy);
	float x = get_height(uv - e.xz) - get_height(uv + e.xz);
	float y = get_height(uv - e.zy) - get_height(uv + e.zy);
	return normalize(vec3(x, e.x * 2.0, y));
}

void vertex() {
	int id = INSTANCE_ID;
	int sfc = int(ceil(VERTEX.y)); // Get the surface num, stored in the y val, 0 for the inner surface, 1 for the outer
	int lvl = int(CAMERA_MATRIX[3].y / 64.0); // Get the current starting instance level, based on the camera's height above the plane, in steps of 64
	lvl = min(lvl, INSTANCE_COUNT - 1); // Cap the lvl at the instance count
	vec3 pos = CAMERA_MATRIX[3].xyz * vec3(1, 0, 1);
	float mul = pow(2.0, float(INSTANCE_ID)); // Get the size mulitplier for each instance, each level is twice the size of the former
	
	bool below = lvl + 1 - id > 0; // true if this vertex is on or below the first active level
	bool above = id + 1 - lvl > 0; // true if this vertex is on or above the first active level
	bool clip = (bool(sfc) || below) && above;
	
//	COLOR = vec4(0.1 * float(id * 2 + sfc), 0, 0.1, 1);
	
//	VERTEX *= vec3(mul, 1.0 / float(clip) - 1.0, mul);
//	VERTEX += pos;
	VERTEX = clip_map(INSTANCE_ID, CAMERA_MATRIX[3].xyz, VERTEX, UV, COLOR);
	UV2 = UV;
	UV *= uv1_scale;
//	NORMAL = calc_normal(UV2, abs(length(CAMERA_MATRIX[3].xyz - VERTEX)));
	NORMAL = calc_normal(UV2, float(id + 1));
	
	position = VERTEX;
	normal = NORMAL;
}

vec4 draw_gizmo(vec4 clr, vec2 uv, vec2 pos) {
	float r = length(uv - pos);
	float w = 1.0 / terrain_diameter * 2.0;
	return r > brush_scale || r < brush_scale - w ? vec4(0) : clr;
}

vec4 texture_triplanar(sampler2DArray sampler, vec3 tex_pos, float layer, vec3 blend) {
	vec4 tx = texture(terrain_textures, vec3(tex_pos.yz, layer));
	vec4 ty = texture(terrain_textures, vec3(tex_pos.xz, layer));
	vec4 tz = texture(terrain_textures, vec3(tex_pos.xy, layer));
	return (tx * blend.x + ty * blend.y + tz * blend.z);
}

vec4 get_mask_for(int layer, vec2 msk_uv) {
	int x = (layer / 4);
	x = x % 2;
	int y = layer / 8;
	vec2 region = vec2(float(x), float(y)) / MASK_SCALE;
	vec4 msk_clr = texture(terrain_masks, msk_uv + region);
	return msk_clr;
}

vec4 blend_alpha(vec4 dst, vec4 src) {
	float a = src.a + dst.a * (1.0 - src.a);
	vec3 rgb = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / a;
	return vec4(rgb, a);
}

vec4 blend_terrain(vec2 uv2, vec3 uv3d, vec3 tri_blend) {
	vec4 clr = vec4(0);
	float alpha = 0.0;
	vec2 msk_uv = uv2 / MASK_SCALE;
	vec4 msk;
	vec4 alb[4];
	
	for (int i = 0; i < NUM_LAYERS; i += 4) {
		msk = get_mask_for(i, msk_uv);
		
		for (int j = 0; j < 4; j++) {
			int lyr = i + j;
			uint flg = uint(pow(2.0, float(lyr)));
			
			if ((flg & use_triplanar) > uint(0)) {
				alb[j] = texture_triplanar(terrain_textures, uv3d, float(lyr), tri_blend);
			}
			else {
				alb[j] = texture(terrain_textures, vec3(uv3d.xz, float(lyr)));
			}
		}
		
		clr += alb[0] * msk[0];
		clr += alb[1] * msk[1];
		clr += alb[2] * msk[2];
		clr += alb[3] * msk[3];
		
		alpha += msk[0];
		alpha += msk[1];
		alpha += msk[2];
		alpha += msk[3];
	}
	
	vec4 bclr = vec4(1, 0, 1, 1);
	clr = clr / (alpha < 1.0 ? 1.0 : alpha);
	clr.a = alpha;
//	clr = blend_alpha(vec4(1, 0, 1, 1), clr);
	return clr;
}

void fragment() {
	vec3 uv3d = position;
	uv3d = uv3d / terrain_diameter * vec3(uv1_scale.x, (uv1_scale.x + uv1_scale.y)/2.0, uv1_scale.y);
	vec3 b = normal;
	b = normalize(vec3(b.x * b.x, b.y * b.y * 16.0, b.z * b.z));
	
	vec4 giz = draw_gizmo(vec4(1, 0, 1, 1), UV2, brush_pos);
	
	ALBEDO = blend_terrain(UV2, uv3d, b).rgb + giz.rgb;
//	ALBEDO = texture(terrain_masks, UV2).rgb;
//	ALBEDO = clr.rgb;
//	ALBEDO = COLOR.rgb;
}