shader_type canvas_item;
// 统一天空 shader：按天空相位从 zenith_gradient 直接采样背景色。

uniform sampler2D zenith_gradient;
// phase: 0=午夜, 0.25=日出, 0.5=正午, 0.75=日落, 1=午夜
uniform float phase : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	float mask_alpha = texture(TEXTURE, UV).a;
	vec3 sky_color = texture(zenith_gradient, vec2(phase, 0.5)).rgb;
	COLOR = vec4(sky_color, mask_alpha);
}
