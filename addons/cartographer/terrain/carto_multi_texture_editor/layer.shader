shader_type canvas_item;
render_mode unshaded;

const int RED = 0, GREEN = 1, BLUE = 2, ALPHA = 3;
uniform int idx = 0;
uniform sampler2DArray texarr : hint_black_albedo;
uniform int channel = -1;
//uniform sampler2D bgtex;

void fragment() {
	vec4 clr = textureLod(texarr, vec3(UV, float(idx)), 0.0);
//	vec4 bg = texture(bgtex, UV * 8.0);
	if (channel == RED) {
		clr = vec4(clr.r, 0, 0, 1)
	}
	else if (channel == GREEN) {
		clr = vec4(0, clr.g, 0, 1)
	}
	else if (channel == BLUE) {
		clr = vec4(0, 0, clr.b, 1)
	}
	else if (channel == ALPHA) {
		clr = vec4(clr.aaa, 1)
	}
	
	COLOR = clr;
}