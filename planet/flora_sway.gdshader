shader_type canvas_item;
render_mode unshaded;
// 相位取世界坐标，使邻近植株共乘同一阵风；位移沿局部横向以免拔出地表。

uniform float sway_pixels = 1.8;
uniform float sway_speed = 1.4;
uniform float world_frequency = 0.08;

void vertex() {
	vec2 world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float height_mask = 1.0 - UV.y;
	height_mask *= height_mask;
	float wind_phase = (
			world_position.x * world_frequency
			+ world_position.y * world_frequency * 0.65
	);
	VERTEX.x += sin(TIME * sway_speed + wind_phase) * sway_pixels * height_mask;
}
