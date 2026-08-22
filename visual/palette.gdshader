shader_type canvas_item;

uniform sampler2D palette : source_color, filter_nearest;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	if (source.a > 0.0) {
		float closest_distance = 4.0; // Greater than the maximum squared RGB distance (3.0).
		vec3 closest_color = source.rgb;
		ivec2 palette_size = textureSize(palette, 0);
		int palette_width = palette_size.x;
		int palette_height = palette_size.y;
		for (int y = 0; y < palette_height; y++)
		{
			float palette_v = (float(y) + 0.5) / float(palette_height);
			for (int x = 0; x < palette_width; x++) {
				float palette_u = (float(x) + 0.5) / float(palette_width);
				vec3 palette_color = texture(palette, vec2(palette_u, palette_v)).rgb;
				float dis = distance(source.rgb, palette_color);
				if (dis < closest_distance) {
					closest_distance = dis;
					closest_color = palette_color;
				}
			}
		}
		COLOR = vec4(closest_color, source.a);
	} else {
		COLOR = source;
	}
}
