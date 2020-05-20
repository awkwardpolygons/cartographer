shader_type spatial;

uniform sampler2D terrain_height;
uniform sampler2D terrain_masks : hint_black;
uniform sampler2DArray terrain_textures : hint_albedo;
uniform vec3 terrain_size;
uniform vec2 uv1_scale = vec2(1, 1);
const int NUM_LAYERS = 16;
const float MASK_SCALE = 2.0;

void vertex() {
//	VERTEX.y = texture(terrain_height, UV).r * terrain_size.y;
	UV = UV * uv1_scale;
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

	ALBEDO = clr.rgb;
}