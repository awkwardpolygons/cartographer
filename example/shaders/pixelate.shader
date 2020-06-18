shader_type canvas_item;

vec4 pixelate(sampler2D sampler, vec2 uv, vec2 factor) {
	vec2 xy = vec2(textureSize(sampler, 0)) * uv;
	xy = xy - mod(xy, factor) + factor / vec2(2, 2);
	return texelFetch(sampler, ivec2(round(xy)), 0);
}

void fragment() {
	COLOR = pixelate(SCREEN_TEXTURE, SCREEN_UV, vec2(4, 4));
}