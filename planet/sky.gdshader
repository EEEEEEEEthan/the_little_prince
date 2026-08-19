shader_type canvas_item;
// 统一天空 shader：按天空相位从 zenith_gradient 采样背景色，
// 并用夜空渐变控制星星的透明度。

uniform sampler2D zenith_gradient : filter_nearest;
uniform sampler2D starfield_tex : hint_default_black, filter_nearest;
uniform sampler2D star_alpha_gradient : hint_default_white, filter_nearest;
uniform sampler2D noise_texture : hint_default_white, filter_nearest;
// phase: 0=午夜, 0.25=日出, 0.5=正午, 0.75=日落, 1=午夜
uniform float phase : hint_range(0.0, 1.0) = 0.5;
uniform float noise_strength : hint_range(0.0, 0.1) = 0.02;

void fragment() {
	float mask_alpha = texture(TEXTURE, UV).a;
	// 量化到噪声纹理像素后取样，噪声附着在像素上而不是随帧跳动。
	vec2 noise_size = vec2(textureSize(noise_texture, 0));
	vec2 noise_uv = (floor(UV * noise_size) + 0.5) / max(noise_size, vec2(1.0));
	float pixel_noise = (texture(noise_texture, noise_uv).r - 0.5) * noise_strength;
	vec3 sky_color = texture(zenith_gradient, vec2(clamp(phase + pixel_noise, 0.0, 1.0), 0.5)).rgb;
	vec4 stars = texture(starfield_tex, UV);
	float star_alpha = texture(star_alpha_gradient, vec2(phase, 0.5)).r;
	vec3 final_color = mix(sky_color, stars.rgb, stars.a * star_alpha);
	COLOR = vec4(final_color, mask_alpha);
}
