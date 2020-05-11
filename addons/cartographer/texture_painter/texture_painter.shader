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

bool within(vec2 uv, vec4 reg) {
	if (all(greaterThan(uv, reg.xy)) && all(lessThan(uv, reg.xy + reg.zw))) {
		return true;
	}
	return false;
}

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

float rectangle(vec2 samplePosition, vec2 halfSize){
    vec2 componentWiseEdgeDistance = abs(samplePosition) - halfSize;
    float outsideDistance = length(max(componentWiseEdgeDistance, 0));
    float insideDistance = min(max(componentWiseEdgeDistance.x, componentWiseEdgeDistance.y), 0);
    return outsideDistance + insideDistance;
}

vec4 blend_alpha(vec4 dst, vec4 src) {
	float a = src.a + dst.a * (1.0 - src.a);
	vec3 rgb = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / a;
	return vec4(rgb, a);
}

vec4 blend_add(vec4 dst, vec4 src) {
	return src + dst;
}

vec4 paint_region(vec2 uv) {
	vec4 regions[4] = { region1, region2, region3, region4 };
	vec4 clr = vec4(0);
	
	vec2 pos = brush_pos/region_grid;
	vec2 pts[] = { pos + region1.xy, pos + region2.xy, pos + region3.xy, pos + region4.xy };
	
	for (int i = 0; i < pts.length(); i++) {
		vec2 pt = uv - pts[i];
//		float c = sdf_circle(pt, 0.1);
		float c = sdf_rbox(pt, vec2(0.1), 0.0);
		if (c < 0.0) {
			if (within(pt + pts[i], regions[i])) {
//				clr = vec4(0, clamp(c * -1.0, 0, 1), 0, 1);
				clr = brush_tex(pt, vec2(0.1)) * brush_strength * brush_strength;
//				if (i != region) {
//					clr *= vec4(-1, -1, -1, 1);
//				}
			}
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
	
	bt = paint_region(SCREEN_UV);
	
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
		COLOR = paint_region(SCREEN_UV) * vec4(0, 0, 0, 1);
	}
}