shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D brush_mask;
uniform vec4 brush_mask_channel = vec4(1, 0, 0, 0);
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

float brush_val(vec2 uv, vec2 scale) {
	uv = uv + ((vec2(0.5) * scale));
	uv = uv/scale;
	float bounds = uv.x > 1.0 || uv.y > 1.0 || uv.x < 0.0 || uv.y < 0.0 ? 0.0 : 1.0;
	return length(texture(brush_mask, uv) * bounds * brush_mask_channel);
}

int which_region(vec2 uv) {
	vec2 loc = clamp(floor(uv * region_grid), vec2(0), region_grid - 1.0);
	return int(region_grid.x * loc.y + loc.x);
}

vec4 paint_masks(sampler2D scr, vec2 uv, vec2 scale, int act) {
	vec4 regions[] = {region1, region2, region3, region4};
	vec2 pos = brush_pos / region_grid;
	vec2 pts[4] = { pos + region1.xy, pos + region2.xy, pos + region3.xy, pos + region4.xy };
	
	bool er = (act & ERASE) > 0;
	int cr = which_region(uv); // Current region, that this texel is in
	int ar = active_region; // Active region, based on the selected layer
	vec4 tx = texture(scr, uv - regions[cr].xy + regions[ar].xy);
	vec4 ch = active_channel; // Active channel, based on the selected layer
	vec2 pt = pts[cr]; // The brush position in this region
	float br = brush_val(uv - pt, scale); // Value of the brush mask at this point
	bool tr = cr == ar; // Is this the targeted region
//	vec4 md = length(tx * ch) < 1.0 && tr && !er ? vec4(0) : vec4(1); // Modifier (add or sub mode)
	vec4 md = length(tx * ch) < 2.0 && !er ? vec4(0) : vec4(1); // Modifier (add or sub mode)
	ch = ch * float(tr && !er) - md;
	return ch * br * brush_strength * brush_strength;
}

vec4 paint_fill(vec2 uv) {
	return float(which_region(uv) == active_region) * active_channel * 2.0;
}

vec4 paint_height(vec2 uv, vec2 scale) {
	vec2 pt = uv - brush_pos;
	float h = brush_val(pt, scale);
	h = h * brush_strength * brush_strength;
	vec4 hgt = vec4(0);
	hgt.x = h;
	hgt.y = dFdx(h) + h;
	hgt.z = dFdy(h) + h;
//	nrm.z = sqrt(1.0 - nrm.x*nrm.x - nrm.y * nrm.y);
	return hgt;
}

void fragment() {
	vec4 st;
	vec4 tt;
	vec4 bt = vec4(0);
	
	bool on = (action & ON) > 0;
	int act = action & (~ON);
	act = act & (~JUST_CHANGED);
	
	if (act != NONE) {
		st = texture(SCREEN_TEXTURE, SCREEN_UV);
	}
	else {
		tt = texture(TEXTURE, SCREEN_UV);
	}
	
	if (act == NONE) {
		COLOR = tt;
	}
	else if (!on) {
		COLOR = st;
	}
	else if (act == RAISE) {
		bt = paint_height(SCREEN_UV, vec2(brush_scale));
		COLOR = clamp(st + bt, 0.0, 1.0);
	}
	else if (act == LOWER) {
		bt = paint_height(SCREEN_UV, vec2(brush_scale));
		COLOR = clamp(st - bt, 0.0, 1.0);
	}
	else if ((act & (PAINT | ERASE)) > 0) {
		bt = paint_masks(SCREEN_TEXTURE, SCREEN_UV, vec2(brush_scale), act);
		COLOR = clamp(st + bt, 0.0, 2.0);
	}
	else if (act == FILL) {
		COLOR = paint_fill(SCREEN_UV);
	}
	else if (act == CLEAR) {
		COLOR = vec4(0);
	}
}