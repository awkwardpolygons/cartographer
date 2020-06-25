shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D brush_mask;
uniform int brush_mask_channel = 0;
uniform int action = 0;
uniform vec2 brush_pos;
uniform vec4 brush_color;
uniform float brush_strength = 0.25;
uniform float brush_scale = 0.25;
uniform float brush_rotation = 0.0;
uniform float brush_strength_jitter = 0.0;
uniform float brush_scale_jitter = 0.0;
uniform float brush_rotation_jitter = 0.0;
uniform int active_region = 0;
uniform vec4 active_channel = vec4(1, -1, -1, -1);
const vec4 SUBTRACT_CHANNELS = vec4(-1);
const int NONE = 0, JUST_CHANGED = 1, ON = 2, RAISE = 4, LOWER = 8, PAINT = 16, ERASE = 32, FILL = 64, CLEAR = 128;
const vec4 region1 = vec4(0, 0, 0.5, 0.5);
const vec4 region2 = vec4(0.5, 0, 0.5, 0.5);
const vec4 region3 = vec4(0, 0.5, 0.5, 0.5);
const vec4 region4 = vec4(0.5, 0.5, 0.5, 0.5);
const vec2 region_grid = vec2(2.0, 2.0);

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

float get_brush_mask_channel(vec4 clr) {
	float c = 0.0;
	
	switch (brush_mask_channel) {
		case 0:
			c = clr.r;
			break;
		case 1:
			c = clr.g;
			break;
		case 2:
			c = clr.b;
			break;
		case 3:
			c = clr.a;
			break;
	}
	
	return c;
}

vec4 paint_masks2(vec4 msk, vec2 uv, vec2 scale, int act) {
	vec4 regions[4] = { region1, region2, region3, region4 };
	vec4 clr = vec4(0);
	
	vec2 pos = brush_pos / region_grid;
	vec2 pts[] = { pos + region1.xy, pos + region2.xy, pos + region3.xy, pos + region4.xy };
	vec4 chn = vec4(-1);
	vec4 sel = vec4(0);
	float val= 0.0;
	
	for (int i = 0; i < regions.length(); i++) {
		vec2 pt = uv - pts[i];
		vec4 rg = regions[i];
		float ar = float(active_region == i);
		sel = clamp(active_channel, 0.0, 1.0);
		vec4 sub = length(sel * msk) < 1.0 && ar == 1.0 ? vec4(0) : vec4(1);
		chn = sel * ar - sub;
		
		float c = sdf_rbox(pt, scale, 0.0);
		if (c < 0.0) {
			if (within(pt + pts[i], rg)) {
				clr = get_brush_mask_channel(brush_tex(pt, scale)) * brush_strength * chn;
			}
		}
	}
	
	return clr;
}

vec4 paint_masks(vec2 uv, vec2 scale, int act) {
	vec4 regions[4] = { region1, region2, region3, region4 };
	vec4 clr = vec4(0);
	
	vec2 pos = brush_pos/region_grid;
	vec2 pts[] = { pos + region1.xy, pos + region2.xy, pos + region3.xy, pos + region4.xy };
	vec4 chn = vec4(-1, -1, -1, -1) / 15.0;
	
	for (int i = 0; i < regions.length(); i++) {
		vec2 pt = uv - pts[i];
		vec4 rg = regions[i];
		
		if (active_region == i && act != ERASE) {
			chn = active_channel;
		} else {
			chn = SUBTRACT_CHANNELS;
		}
		
		if (act == FILL && within(uv, rg)) {
			clr = chn;
		}
		else {
			float c = sdf_rbox(pt, scale, 0.0);
			if (c < 0.0) {
				if (within(pt + pts[i], regions[i])) {
					clr = get_brush_mask_channel(brush_tex(pt, scale)) * brush_strength * chn;
				}
			}
		}
	}
	
	return clr;
}

vec4 paint_height(vec2 uv, vec2 scale) {
	vec4 chn = vec4(1, 0, 0, 0);
	vec2 pt = uv - brush_pos;
	vec4 clr = brush_tex(pt, scale);
	float h = get_brush_mask_channel(clr);
	return h * brush_strength * brush_strength * chn;
}

void fragment() {
	vec4 st = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 tt = texture(TEXTURE, SCREEN_UV);
	vec4 bt = vec4(0);
	
	bool on = (action & ON) > 0;
	int act = action & (~ON);
	act = act & (~JUST_CHANGED);
	
	if (act == NONE) {
		COLOR = tt;
	}
	else if (!on) {
		COLOR = st;
	}
	else if (act == RAISE) {
		bt = paint_height(SCREEN_UV, vec2(brush_scale));
		COLOR = st + bt;
	}
	else if (act == LOWER) {
		bt = paint_height(SCREEN_UV, vec2(brush_scale));
		COLOR = clamp(st - bt, 0.0, 1.0);
	}
	else if ((act & (PAINT | ERASE)) > 0) {
//		bt = paint_masks(SCREEN_UV, vec2(brush_scale), act);
		bt = paint_masks2(st, SCREEN_UV, vec2(brush_scale), act);
		COLOR = st + bt;
	}
	else if (act == FILL) {
		COLOR = paint_masks(SCREEN_UV, vec2(brush_scale), act);
	}
	else if (act == CLEAR) {
		COLOR = vec4(0);
	}
}