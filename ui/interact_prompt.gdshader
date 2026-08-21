shader_type canvas_item;
render_mode unshaded;

uniform float fill_ratio : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	if (fill_ratio <= 0.0) {
		COLOR = texel;
		return;
	}
	vec2 from_center = UV * 2.0 - 1.0;
	float angle_turns = atan(from_center.x, -from_center.y) / TAU + 0.5;
	float filled = step(angle_turns, fill_ratio);
	COLOR = vec4(texel.rgb * mix(0.35, 1.0, filled), texel.a);
}
