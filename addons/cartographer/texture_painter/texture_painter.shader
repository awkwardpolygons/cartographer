shader_type canvas_item;

uniform bool clear;
uniform sampler2D brush_mask;
uniform vec2 brush_pos;
uniform vec4 brush_color;


float squircle(vec2 uv, vec2 pos, float r) {
	vec2 tmp = pow(uv - pos, vec2(4));
	return tmp.x + tmp.y - pow(r, 4);
}

float rectangle(vec2 uv, vec2 pos, float r) {
	vec2 tmp = abs(uv - pos) - r;
	return max(tmp.x, tmp.y) * -1.0;
}

vec4 brush(vec2 uv, vec4 color) {
	return smoothstep(0.2, 0.1, length(uv - brush_pos)) * color;
//	return rectangle(uv, brush_pos, 0.25) * color;
}

void fragment() {
	vec4 st = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 tt = texture(TEXTURE, SCREEN_UV);
	
	vec4 bt = brush(SCREEN_UV, vec4(1, 0, 0, 1));
	
	if(clear) {
		COLOR = tt
	}
	else {
		COLOR = st + bt;
	}
}