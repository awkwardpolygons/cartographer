shader_type canvas_item;

const int RED = 1, GREEN = 2, BLUE = 4, ALPHA = 8;
uniform int idx = 0;
uniform sampler2DArray texarr : hint_black_albedo;
uniform int channel = 0;
//uniform sampler2D bgtex;

void fragment() {
	vec4 clr = textureLod(texarr, vec3(UV, float(idx)), 0.0);
//	vec4 bg = texture(bgtex, UV * 8.0);
	if (channel == RED) {
		clr = vec4(clr.r, 0, 0, 1)
	}
	if (channel == GREEN) {
		clr = vec4(0, clr.g, 0, 1)
	}
	if (channel == BLUE) {
		clr = vec4(0, 0, clr.b, 1)
	}
	if (channel == ALPHA) {
		clr = vec4(clr.aaa, 1)
	}
	
	COLOR = clr;
}