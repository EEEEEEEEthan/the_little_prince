shader_type canvas_item;
render_mode unshaded;

uniform float fill_ratio : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec2 from_center = UV * 2.0 - 1.0;
	float angle_turns = atan(from_center.x, -from_center.y) / TAU + 0.5;
	float filled = step(angle_turns, fill_ratio);
	float holding = 1.0 - step(fill_ratio, 0.0);
	float brightness = mix(1.0, mix(0.35, 1.0, filled), holding);
	COLOR = vec4(texel.rgb * brightness, texel.a);
}
