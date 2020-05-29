shader_type spatial;

uniform sampler2D terrain_height : hint_black;
uniform sampler2D terrain_masks : hint_black;
uniform sampler2DArray terrain_textures : hint_albedo;
uniform vec3 terrain_size;
uniform vec2 uv1_scale = vec2(4);
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
	vec3 off = clamp(cam, size * -1.0, size);
	// Set the stride, or number of units it moves per step,
	// which is the max quad size (16) so you don't get wavy terrain.
	off = floor(off / 16.0) * 16.0;
	// Double the size of the mesh so we have some overlap to clip as it moves
	vtx *= 2.0;
	
	// Calculate the terrain uv
	uv = ((vtx.xz + off.xz) / terrain_size.xz) + 0.5;
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

void normal(inout vec3 nm, vec2 uv) {
	vec3 e = vec3(1.0 / terrain_size.xz, 0.0);
	float x = get_height(uv + e.xz) - get_height(uv - e.xz);
	float y = get_height(uv + e.zy) - get_height(uv - e.zy);
	nm = normalize(vec3(-x, e.x * 2.0, -y));
}

void vertex() {
	clipmap(CAMERA_MATRIX[3].xyz, VERTEX, UV, clipped);
	
	UV2 = UV;
	UV *= uv1_scale;
	normal(NORMAL, UV2);
	
	// If the vertex has moved beyond the bounds, discard it by setting it to
	// Inf or NaN. Is this a stable alternative to `discard` in the fragment shader?
	if (clipped > 0.0) {
//		VERTEX = vec3(sqrt(-1.0)); // NaN
		VERTEX = vec3(1.0 / 0.0); // Inf
	}
	
	world_pos = VERTEX;
	world_norm = NORMAL;
}

float get_channel(vec4 val, int idx) {
	idx = idx % 4;
	switch (idx) {
		case 0:
			return val[0];
		case 1:
			return val[1];
		case 2:
			return val[2];
		case 3:
			return val[3];
	}
}

void normalmap(inout vec3 nm, vec2 uv) {
	vec3 e = vec3(1.0 / terrain_size.xz, 0.0);
	float x = get_height(uv + e.xz) - get_height(uv - e.xz);
	float y = get_height(uv + e.zy) - get_height(uv - e.zy);
	nm = normalize(vec3(x, y, e.x));
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

void fragment() {
	normalmap(NORMALMAP, UV2);
//	normal(NORMAL, UV2);
	
//	vec3 p = vec3(UV.xy, get_height(UV2));
//	vec3 p = VERTEX * mat3(INV_CAMERA_MATRIX) + CAMERA_MATRIX[3].xyz;
	vec3 p = world_pos;
	p = p / terrain_size.x * uv1_scale.xxx;
//	p = p.xzy;
//	vec3 b = abs(NORMALMAP);
//	vec3 b = NORMALMAP * NORMALMAP;
//	b = b.xzy;
//	b = normalize(max(b, vec3(0.00001))) / (b.x + b.y + b.z);
	vec3 b = world_norm;
	b = normalize(vec3(b.x * b.x, b.y * b.y * 8.0, b.z * b.z));
//	b *= b;
//	vec3 b = triplanar_blend_1(world_norm);
	
	
//	vec4 mask = texture(terrain_masks, UV / uv1_scale);
//	vec4 color = texture(terrain_textures, vec3(UV.xy, 0));
//	ALBEDO = mask.rgb;
	
	vec4 clr = vec4(0);
	vec4 tex = vec4(0);
	vec4 msk = vec4(0);
	vec2 msk_uv = UV / uv1_scale / MASK_SCALE;
	for (int i = 0; i < NUM_LAYERS; i++) {
		int x = (i / 4);
		x = x % 2;
		int y = i / 8;
		vec2 region = vec2(float(x), float(y)) / MASK_SCALE;
		msk = texture(terrain_masks, msk_uv + region);
//		tex = texture(terrain_textures, vec3(UV.xy, float(i)));
//		vec4 tx = texture(terrain_textures, vec3(p.yz, float(i)));
//		vec4 ty = texture(terrain_textures, vec3(p.xz, float(i)));
//		vec4 tz = texture(terrain_textures, vec3(p.xy, float(i)));
//		tex = (tx * b.x + ty * b.y + tz * b.z);
//		tex = ty;
		tex = texture_triplanar(terrain_textures, p, float(i), b);
		clr += tex * get_channel(msk, i);
	}
	
//	ALBEDO = NORMAL;
	ALBEDO = clr.rgb;
//	ALBEDO = texture(terrain_height, UV).rgb;
}