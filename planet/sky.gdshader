shader_type canvas_item;
// 统一天空 shader：用 day_sky 贴图红通道作高度 mask，
// 天顶/地平线渐变从 zenith_gradient/horizon_gradient 按 phase 取色，
// 夜空贴图（starfield）按 phase 从 night_sky_gradient 取透明度叠加，
// 最后叠加胶片颗粒（film grain）效果。

uniform sampler2D zenith_gradient;
uniform sampler2D horizon_gradient;
uniform sampler2D night_sky_gradient;
uniform sampler2D day_sky_tex : hint_default_white;
uniform sampler2D starfield_tex : hint_default_black;
// phase: 0=午夜, 0.25=日出, 0.5=正午, 0.75=日落, 1=午夜
uniform float phase : hint_range(0.0, 1.0) = 0.5;
// grain: 颗粒强度，建议 0.02–0.06
uniform float grain_strength : hint_range(0.0, 0.2) = 0.035;
// 低质量哈希噪声（无 texture 依赖，使用天空贴图坐标保持颗粒随天空移动）
float hash(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

void fragment() {
	// --- 白天天空：day_sky 贴图红通道作高度 ---
	vec4 day_mask = texture(day_sky_tex, UV);
	vec3 day_color = mix(
		texture(horizon_gradient, vec2(phase, 0.5)).rgb,
		texture(zenith_gradient, vec2(phase, 0.5)).rgb,
		day_mask.r
	);

	// --- 夜空：starfield 贴图，alpha 由 night_sky_gradient 控制 ---
	vec4 stars = texture(starfield_tex, UV);
	float night_alpha = texture(night_sky_gradient, vec2(phase, 0.5)).r;
	vec3 blended = mix(day_color, stars.rgb, stars.a * night_alpha);

	// --- 胶片颗粒（film grain）---
	// 使用天空贴图像素坐标作为种子，避免颗粒固定在屏幕上
	vec2 sky_pixel = floor(UV * vec2(textureSize(day_sky_tex, 0)));
	float grain = hash(sky_pixel) - 0.5;
	blended += grain * grain_strength;

	// --- 输出：整体 alpha 取 day_sky 遮罩 alpha（圆形裁切）---
	COLOR = vec4(blended, day_mask.a);
}
