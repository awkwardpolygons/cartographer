shader_type canvas_item;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 factor = vec2(4, 4);
	vec2 xy = vec2(textureSize(SCREEN_TEXTURE, 0)) * uv;
	xy = xy - mod(xy, factor) + factor / vec2(2, 2);
	//vec2 px = SCREEN_PIXEL_SIZE * vec2(4, 4);
	//vec2 uv = SCREEN_UV - mod(SCREEN_UV, px);
	//ivec2 xy = ivec2(vec2(1, 1) / SCREEN_PIXEL_SIZE * uv);
	COLOR = texelFetch(SCREEN_TEXTURE, ivec2(round(xy)), 0);
}