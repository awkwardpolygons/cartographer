shader_type canvas_item;

const int NONE = 0, PAINT = 1, ERASE = 2, CLEAR = 3;

uniform sampler2D brush_mask;
uniform int action = 0;
uniform vec2 brush_pos;
uniform vec4 brush_color;
// TODO: uniform vec4 segment = vec4(0, 0, 512, 512);

float squircle(vec2 uv, vec2 pos, float r) {
	vec2 tmp = pow(uv - pos, vec2(4));
	return tmp.x + tmp.y - pow(r, 4);
}

float rectangle(vec2 uv, vec2 pos, float r) {
	vec2 tmp = abs(uv - pos) - r;
	return max(tmp.x, tmp.y) * -1.0;
}

vec4 brush(vec2 uv, vec4 color) {
//	return smoothstep(0.2, 0.1, length(uv - brush_pos)) * color;
	color.a = smoothstep(0.1, 0.025, length(uv - brush_pos));
	return color;
//	return rectangle(uv, brush_pos, 0.25) * color;
}

vec4 alpha_blend(vec4 dst, vec4 src) {
	float a = src.a + dst.a * (1.0 - src.a);
	vec3 rgb = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / a;
	return vec4(rgb, a);
}

vec4 blend_add(vec4 dst, vec4 src) {
	return src + dst;
}

void fragment() {
	vec4 st = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 tt = texture(TEXTURE, SCREEN_UV);
	
	vec4 bt = brush(SCREEN_UV, vec4(0.01, 0, 0, 1));
	
	
	
	if (action == CLEAR) {
		COLOR = tt;
	}
	else if (action == PAINT) {
//		COLOR.rgb = mix(st.rgb, bt.rgb, bt.a);
		COLOR = blend_add(st, bt);
//		COLOR = alpha_blend(st, bt);
//		COLOR = st + bt;
	}
	else if (action == ERASE) {
		COLOR = brush(SCREEN_UV, vec4(0, 0, 0, 0));
	}
}