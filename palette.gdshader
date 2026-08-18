shader_type canvas_item;

uniform sampler2D palette : source_color, filter_nearest;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	if (source.a <= 0.0) {
		COLOR = source;
		return;
	}

	float closest_distance = 3.0; // Maximum squared distance between RGB colors.
	vec3 closest_color = source.rgb;
	int palette_width = textureSize(palette, 0).x;
	for (int index = 0; index < palette_width; index++) {
		float palette_u = (float(index) + 0.5) / float(palette_width);
		vec3 palette_color = texture(palette, vec2(palette_u, 0.5)).rgb;
		float distance = dot(source.rgb - palette_color, source.rgb - palette_color);
		if (distance < closest_distance) {
			closest_distance = distance;
			closest_color = palette_color;
		}
	}
	COLOR = vec4(closest_color, source.a);
}
