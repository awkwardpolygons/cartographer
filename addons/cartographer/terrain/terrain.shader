shader_type spatial;

uniform sampler2D texture : hint_albedo;
uniform sampler2D terrain_masks;
uniform sampler2DArray terrain_layers;
uniform vec3 terrain_size;

void vertex() {
//	VERTEX.y = texture(texture, UV).r * terrain_size.y;
}

void fragment() {
//	ALBEDO = texture(terrain_masks, UV).rgb;
	ALBEDO = texture(terrain_layers, vec3(UV.xy, 0)).rgb;
//	ALBEDO = vec3(UV.xy, 0);
}