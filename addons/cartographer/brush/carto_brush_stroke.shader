shader_type canvas_item;
varying float idx;
varying vec4 clr;

void vertex() {
//	VERTEX.y += sin(fract(TIME) / 20.0 * VERTEX.y) * 10.0;
//	VERTEX *= 10.0 * fract(TIME/100.0) + 1.0;
	idx = INSTANCE_CUSTOM.x;
	clr = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV * vec2(1, 2), 1.0);
//	vec4 stex = texture(SCREEN_TEXTURE, SCREEN_UV, 0.0);
//	COLOR = vec4(1.0, 0, 0, tex.a * 0.33);
//	COLOR = clamp((tex.r * 2.0 - 1.0), 0, 1) * vec4(0.2, 0.6, 0.1, 1);
//	COLOR.a = clamp(0.5 - length(UV - 0.5), 0 ,1);
	COLOR = vec4(clr.rgb, tex.a);
}