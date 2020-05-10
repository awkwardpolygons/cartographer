shader_type canvas_item;

uniform sampler2D brush_mask;
uniform int action = 0;
uniform vec2 brush_pos;
uniform vec4 brush_color;
uniform float brush_strength = 0.25;
uniform float brush_scale = 0.25;
uniform float brush_rotation = 0.0;
uniform float brush_strength_jitter = 0.0;
uniform float brush_scale_jitter = 0.0;
uniform float brush_rotation_jitter = 0.0;
const int NONE = 0, PAINT = 1, ERASE = 2, CLEAR = 3;


// TODO:
const vec4 region1 = vec4(0, 0, 0.5, 0.5);
const vec4 region2 = vec4(0.5, 0, 0.5, 0.5);
const vec4 region3 = vec4(0, 0.5, 0.5, 0.5);
const vec4 region4 = vec4(0.5, 0.5, 0.5, 0.5);
const vec2 region_grid = vec2(2.0, 2.0);
uniform int region = 0;
uniform vec4 channel = vec4(1, -1, -1, -1);


vec4 brush_tex(vec2 uv, vec2 scale) {
	uv = uv + ((vec2(0.5) * scale));
	uv = uv/scale;
	if (uv.x > 1.0 || uv.y > 1.0 || uv.x < 0.0 || uv.y < 0.0) {
		return vec4(0, 0, 0, 0);
	}
	return texture(brush_mask, uv);
}

float sdf_circle(vec2 p, float r) {
	return length(p) - r/2.0;
}

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

float rectangle(vec2 samplePosition, vec2 halfSize){
    vec2 componentWiseEdgeDistance = abs(samplePosition) - halfSize;
    float outsideDistance = length(max(componentWiseEdgeDistance, 0));
    float insideDistance = min(max(componentWiseEdgeDistance.x, componentWiseEdgeDistance.y), 0);
    return outsideDistance + insideDistance;
}

vec4 blend_add(vec4 dst, vec4 src) {
	return src + dst;
}

vec4 paint_region(vec2 uv) {
	vec4 regions[4] = { region1, region2, region3, region4 };
	vec4 clr = vec4(0);
	vec2 uv2 = uv - brush_pos/region_grid;
	
	for (int i = 0; i < regions.length(); i++) {
		vec4 reg = regions[i];
		vec2 pos = uv2 - reg.xy - 0.05;
		if (pos.x < 0.0 && pos.y < 0.0) {
//			clr = brush_tex(pos, vec2(0.125)) * brush_strength * brush_strength;
			float c = sdf_circle(pos + 0.05, 0.1);
			clr = vec4(0, clamp(c * -1.0, 0, 1), 0, 1);
			clr += vec4(0, 0, 1, 1);
			break;
		}
	}
	
	return clr;
}

void fragment() {
	vec2 brush_ratio = SCREEN_PIXEL_SIZE * vec2(textureSize(brush_mask, 0));
	vec2 brush_rel_uv = SCREEN_UV - brush_pos/region_grid;
	vec4 st = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 tt = texture(TEXTURE, SCREEN_UV);
	vec4 bt = vec4(0);
	
//	bt = brush(brush_rel_uv, vec4(0.2, 0, 0, 0));
//	float a = step(0.0, -1.0 * squircle(brush_pos - SCREEN_UV, 0.25, 4));
//	float a = smoothstep(0.0, 0.3, sdf_rbox(brush_pos - SCREEN_UV, vec2(0.5), 0.5));
//	float a = -1.0 * sdf_rbox(brush_pos - SCREEN_UV, vec2(0.25), 0.15);
//	float a = -1.0 * sdf_rbox(brush_pos - SCREEN_UV, vec2(0.5), 0.5);
//	float a = rectangle(brush_pos - SCREEN_UV, vec2(0.15, 0.15)) - 0.2;
//	bt = vec4(1, 0, 0, a);
//	bt = vec4(a, a, a, 1);
//	bt = brush_tex(brush_rel_uv - region1.xy, brush_ratio * brush_scale) * brush_strength * brush_strength;
//	bt = paint_region(brush_rel_uv, vec4(0))
//	bt = vec4(1, 1, 1, bt.r);
//	bt = vec4(clamp(sdf_circle(brush_rel_uv - region1.xy, 0.1) * -1.0, 0, 1), 0, 0, 1);
//	float c = sdf_circle(brush_rel_uv - region1.xy, 0.1);
//	if (c < 0.0) {
//		bt = vec4(clamp(c * -1.0, 0, 1), 0, 0, 1);
//	}
//	c = sdf_circle(brush_rel_uv - region2.xy, 0.1);
//	if (c < 0.0) {
//		bt = vec4(clamp(c * -1.0, 0, 1), 0, 0, 1);
//	}
//	c = sdf_circle(brush_rel_uv - region3.xy, 0.1);
//	if (c < 0.0) {
//		bt = vec4(clamp(c * -1.0, 0, 1), 0, 0, 1);
//	}
//	c = sdf_circle(brush_rel_uv - region4.xy, 0.1);
//	if (c < 0.0) {
//		bt = vec4(clamp(c * -1.0, 0, 1), 0, 0, 1);
//	}
	
	bt = paint_region(SCREEN_UV);
	
//	vec2 uv = SCREEN_UV;
//	if (uv.x > 0.5 || uv.y > 0.5) {
//		bt = vec4(0, 0, 0, 0);
//	}
	
	if (action == NONE) {
		COLOR = st;
	}
	else if (action == CLEAR) {
		COLOR = vec4(0, 0, 0, 1);
	}
	else if (action == PAINT) {
//		COLOR.rgb = mix(st.rgb, bt.rgb, bt.a);
//		COLOR = blend_alpha(st, bt);
		COLOR = blend_add(st, bt);
//		COLOR = alpha_blend(st, bt);
//		COLOR = st + bt;
	}
	else if (action == ERASE) {
		COLOR = brush(SCREEN_UV, vec4(0, 0, 0, 0));
	}
}