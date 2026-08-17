shader_type canvas_item;
// 白天天空：day_sky 贴图红通道当高度坐标（最红=天顶、最黑=地平线），
// 天顶/地平线渐变色分别来自 zenith_gradient / horizon_gradient（按相位采样），
// 相位由 Starfield 按星空相对角度写入。

uniform sampler2D zenith_gradient;
uniform sampler2D horizon_gradient;
uniform float phase : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 mask_sample = texture(TEXTURE, UV);
	vec3 sky_color = mix(
		texture(horizon_gradient, vec2(phase, 0.5)).rgb,
		texture(zenith_gradient, vec2(phase, 0.5)).rgb,
		mask_sample.r
	);
	COLOR = vec4(sky_color, mask_sample.a);
}
