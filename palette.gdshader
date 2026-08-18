shader_type canvas_item;

uniform sampler2D palette : source_color, filter_nearest;
uniform int palette_size = 32;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	if (source.a <= 0.0) {
		COLOR = source;
		return;
	}

	float closest_distance = 1e6;
	vec3 closest_color = source.rgb;
	for (int index = 0; index < palette_size; index++) {
		float palette_u = (float(index) + 0.5) / float(palette_size);
		vec3 palette_color = texture(palette, vec2(palette_u, 0.5)).rgb;
		float distance = dot(source.rgb - palette_color, source.rgb - palette_color);
		if (distance < closest_distance) {
			closest_distance = distance;
			closest_color = palette_color;
		}
	}
	COLOR = vec4(closest_color, source.a);
}
