shader_type canvas_item;
render_mode unshaded;

uniform float frame_columns = 4.0;
uniform float frame_rows = 8.0;

void vertex() {
	float row_index = floor(COLOR.r * (frame_rows - 1.0) + 0.5);
	float start_frame = COLOR.g * frame_columns;
	float animation_speed = mix(0.55, 1.35, COLOR.b);
	float frame_index = floor(mod(start_frame + TIME * 2.0 * animation_speed, frame_columns));
	UV = vec2((UV.x + frame_index) / frame_columns, (UV.y + row_index) / frame_rows);
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	COLOR = vec4(texel.rgb, texel.a * COLOR.a);
}
