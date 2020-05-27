shader_type spatial;

uniform sampler2D terrain_height : hint_black;
uniform sampler2D terrain_masks : hint_black;
uniform sampler2DArray terrain_textures : hint_albedo;
uniform vec3 terrain_size;
uniform vec2 uv1_scale = vec2(1, 1);
const int NUM_LAYERS = 16;
const float MASK_SCALE = 2.0;
varying float clipped;

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

void vertex() {
	clipmap(CAMERA_MATRIX[3].xyz, VERTEX, UV, clipped);
	
	UV *= uv1_scale;
	
	// If the vertex has moved beyond the bounds, discard it by setting it to
	// Inf or NaN. Is this a stable alternative to `discard` in the fragment shader?
	if (clipped > 0.0) {
//		VERTEX = vec3(sqrt(-1.0)); // NaN
		VERTEX = vec3(1.0 / 0.0); // Inf
	}
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

void fragment() {
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
		tex = texture(terrain_textures, vec3(UV.xy, float(i)));
		clr += tex * get_channel(msk, i);
	}

//	ALBEDO = clr.rgb;
	ALBEDO = texture(terrain_height, UV).rgb;
}