shader_type canvas_item;

uniform sampler2D brush_mask;
uniform int action = 0;
uniform vec2 brush_pos;
uniform vec4 brush_color;
// TODO: uniform vec4 segment = vec4(0, 0, 512, 512);
const int NONE = 0, PAINT = 1, ERASE = 2, CLEAR = 3;


float sdf_rbox(vec2 p, vec2 s, float r) {
	s = s/2.0;
	r = r/4.0;
	vec2 q = abs(p) - s + r;
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float sdf_squircle(vec2 p, float s, float n) {
	return pow(abs(p.x), n) + pow(abs(p.y), n) - pow(s/2.0, n);
}

vec4 brush(vec2 uv, vec4 color) {
//	return smoothstep(0.2, 0.1, length(uv - brush_pos)) * color;
	color.a = smoothstep(0.1, 0.025, length(uv - brush_pos));
	return color;
//	return rectangle(uv, brush_pos, 0.25) * color;
}

vec4 blend_alpha(vec4 dst, vec4 src) {
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
	
//	float a = step(0.0, -1.0 * squircle(brush_pos - SCREEN_UV, 0.25, 4));
	float a = step(0.0, -1.0 * sdf_rbox(brush_pos - SCREEN_UV, vec2(0.5), 1.0));
	bt = vec4(1, 0, 0, a);
	
	
	if (action == CLEAR) {
		COLOR = tt;
	}
	else if (action == PAINT) {
//		COLOR.rgb = mix(st.rgb, bt.rgb, bt.a);
		COLOR = blend_alpha(st, bt);
//		COLOR = alpha_blend(st, bt);
//		COLOR = st + bt;
	}
	else if (action == ERASE) {
		COLOR = brush(SCREEN_UV, vec4(0, 0, 0, 0));
	}
}