shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D heightmap;

void fragment() {
	COLOR = texture(TEXTURE, SCREEN_UV, 0.0);
	vec4 hm = texelFetch(heightmap, ivec2(COLOR.xz), 0);
	COLOR.a = COLOR.y <= hm.r ? 1.0 : 0.0;
}
