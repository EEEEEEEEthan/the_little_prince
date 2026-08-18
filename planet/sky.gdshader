shader_type canvas_item;
// 统一天空 shader：按天空相位从 zenith_gradient 采样背景色，
// 并用夜空渐变控制星星的透明度。

uniform sampler2D zenith_gradient;
uniform sampler2D starfield_tex : hint_default_black;
uniform sampler2D star_alpha_gradient : hint_default_white;
// phase: 0=午夜, 0.25=日出, 0.5=正午, 0.75=日落, 1=午夜
uniform float phase : hint_range(0.0, 1.0) = 0.5;
uniform float uv_noise_strength : hint_range(0.0, 0.1) = 0.02;

float hash(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

void fragment() {
	float mask_alpha = texture(TEXTURE, UV).a;
	float uv_noise = (hash(UV * 640.0) - 0.5) * uv_noise_strength;
	vec3 sky_color = texture(zenith_gradient, vec2(clamp(phase + uv_noise, 0.0, 1.0), 0.5)).rgb;
	vec4 stars = texture(starfield_tex, UV);
	float star_alpha = texture(star_alpha_gradient, vec2(phase, 0.5)).r;
	vec3 final_color = mix(sky_color, stars.rgb, stars.a * star_alpha);
	COLOR = vec4(final_color, mask_alpha);
}
