shader_type spatial;

uniform sampler2D texture : hint_albedo;
uniform vec3 terrain_size;

void vertex() {
	VERTEX.y = texture(texture, UV).r * terrain_size.y;
}

void fragment() {
	ALBEDO = texture(texture, UV).rgb;
}