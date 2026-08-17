shader_type canvas_item;
// 白天天空：day_sky 贴图为黑红渐变，红通道当「地平线->天顶」高度坐标，
// 由 Starfield 按星空相对角度（时段）写入两端的真实天空色。

uniform vec4 zenith_color : source_color = vec4(0.36, 0.62, 0.88, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.92, 0.86, 0.66, 1.0);

void fragment() {
	vec4 mask_sample = texture(TEXTURE, UV);
	vec3 sky_color = mix(horizon_color.rgb, zenith_color.rgb, mask_sample.r);
	COLOR = vec4(sky_color, mask_sample.a);
}
