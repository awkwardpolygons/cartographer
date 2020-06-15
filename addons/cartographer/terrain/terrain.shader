shader_type spatial;

uniform sampler2D terrain_height : hint_black;
uniform sampler2D terrain_masks : hint_black;
uniform sampler2DArray terrain_textures : hint_albedo;
uniform vec4 base_color = vec4(1);
uniform vec3 terrain_size;
uniform float sq_dim = 256;
uniform vec2 uv1_scale = vec2(1);
uniform uint use_triplanar = 0;
const float MESH_STRIDE = 16.0;
const int NUM_LAYERS = 16;
const float MASK_SCALE = 2.0;
varying float clipped;
varying vec3 world_pos;
varying vec3 world_norm;

float get_height(vec2 uv) {
	vec2 h = texture(terrain_height, uv).rg;
	return (h.r * 256.0 + h.g) / (256.0);
}

void clipmap(vec3 cam, inout vec3 vtx, inout vec2 uv, inout float clp) {
	// Divide terrain_size by 2 to get the bounds around center, in local space
	vec3 size = terrain_size / 2.0;
	// cam is the camera offset, limit it to within the bounds of the terrain size
	vec3 off = clamp(cam, sq_dim / 2.0 * -1.0, sq_dim / 2.0);
	// Set the stride, or number of units it moves per step,
	// which is the max quad size (16) so you don't get wavy terrain.
	off = floor(off / MESH_STRIDE) * MESH_STRIDE;
	// Double the size of the mesh so we have some overlap to clip as it moves
	vtx *= 2.0;
	
	// Calculate the terrain uv
	uv = ((vtx.xz + off.xz) / sq_dim) + 0.5;
	// Get the height from the heightmap
//	off.y = texture(terrain_height, uv).r * terrain_size.y;
//	vec2 h = texture(terrain_height, uv).rg;
//	off.y = (h.r * 256.0 + h.g) / (256.0) * terrain_size.y;
	off.y = get_height(uv) * terrain_size.y;
	
	// Offset the vertex
	vtx += off;
	// If the vertex has moved beyond the bounds, set clipped as 1.0
	clp = abs(vtx.x) > size.x || abs(vtx.z) > size.z ? 1.0 : 0.0;
}

vec3 calc_normal(vec2 uv) {
	// TODO: Modify this gradient step resolution based on the density of the mesh,
	// vertices closer together use smaller steps to calc normal, vertices further
	// apart use larger steps.
	vec3 e = vec2(1.0 / sq_dim, 0.0).xxy;
//	float x = h - get_height(uv + e.xz);
//	float y = h - get_height(uv + e.zy);
	float x = get_height(uv - e.xz) - get_height(uv + e.xz);
	float y = get_height(uv - e.zy) - get_height(uv + e.zy);
	return normalize(vec3(x, e.x * 2.0, y));
}

void vertex() {
	clipmap(CAMERA_MATRIX[3].xyz, VERTEX, UV, clipped);
	
	UV2 = UV;
	UV *= uv1_scale;
//	normal(NORMAL, UV2);
	NORMAL = calc_normal(UV2);
	
	// If the vertex has moved beyond the bounds, discard it by setting it to
	// Inf or NaN. Is this a stable alternative to `discard` in the fragment shader?
	if (clipped > 0.0) {
//		VERTEX = vec3(sqrt(-1.0)); // NaN
		VERTEX = vec3(1.0 / 0.0); // Inf
	}
	
	world_pos = VERTEX;
	world_norm = NORMAL;
}

// "Standard" triplanar blending.
vec3 triplanar_blend_1(vec3 normal) {
	vec3 blend_weights = abs(normal); 
    
    float blend_zone = 0.55; // Anything over 1/sqrt(3) or .577 will produce negative values in corner
	blend_weights = blend_weights - blend_zone; 

	blend_weights = max(blend_weights, 0.0);     
	float rcp_blend = 1.0 / (blend_weights.x + blend_weights.y + blend_weights.z);
	return blend_weights * rcp_blend;
}

// Constant width Triplanar blending
vec3 triplanar_blend_2(vec3 normal) {
	vec3 blend_weights = normal * normal; // or abs(normal) for linear falloff(and adjust blend_zone)
	float max_blend = max(blend_weights.x, max(blend_weights.y, blend_weights.z));
 	
    float blend_zone = 0.8f;
	blend_weights = blend_weights - max_blend * blend_zone;

	blend_weights = max(blend_weights, 0.0);   

	float rcp_blend = 1.0 / (blend_weights.x + blend_weights.y + blend_weights.z);
	return blend_weights * rcp_blend;
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

void fragment() {
	vec3 nrm = calc_normal(UV2);
	NORMAL = (vec4(nrm, 1.0) * CAMERA_MATRIX).xyz;
//	NORMALMAP = nrm.xzy * vec3(1, -1, 1);
//	normalmap(NORMALMAP, UV2);
//	NORMALMAP = calc_normal(UV2).xzy * vec3(1, -1, 1);
//	NORMAL = calc_normal(UV2) * mat3(CAMERA_MATRIX);
//	normal(NORMAL, UV2);
	
//	vec4 mask = texture(terrain_masks, UV / uv1_scale);
//	vec4 color = texture(terrain_textures, vec3(UV.xy, 0));
//	ALBEDO = mask.rgb;
	
	vec3 p = world_pos;
//	p = p / terrain_size.x * uv1_scale.xxx;
	p = p / sq_dim * vec3(uv1_scale.x, (uv1_scale.x + uv1_scale.y)/2.0, uv1_scale.y);
//	vec3 b = calc_normal(UV2);
	vec3 b = world_norm;
	b = normalize(vec3(b.x * b.x, b.y * b.y * 16.0, b.z * b.z));
	
	vec4 clr = vec4(0);
	float alpha = 0.0;
	vec2 msk_uv = UV / uv1_scale / MASK_SCALE;
	vec4 msk;
	vec4 alb[4];
	
	for (int i = 0; i < NUM_LAYERS; i += 4) {
		msk = get_mask_for(i, msk_uv);
		
		for (int j = 0; j < 4; j++) {
			int lyr = i + j;
			uint flg = uint(pow(2.0, float(lyr)));
			
			if ((flg & use_triplanar) > uint(0)) {
				alb[j] = texture_triplanar(terrain_textures, p, float(lyr), b);
			}
			else {
				alb[j] = texture(terrain_textures, vec3(p.xz, float(lyr)));
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
	
//	ALBEDO = NORMAL;
//	ALBEDO = texture(terrain_textures, vec3(UV, 0)).rgb;
//	ALBEDO = texture(terrain_masks, UV / 2.0).rgb;
	ALBEDO = clr.rgb;
//	ALBEDO = (clr.rgb / alpha) + base_color.rgb * (1.0 - clamp(alpha, 0.0, 1.0));
//	ALBEDO = clr.rgb + base_color.rgb * (1.0 - alpha);
//	ALBEDO = texture(terrain_height, UV).rgb;
}