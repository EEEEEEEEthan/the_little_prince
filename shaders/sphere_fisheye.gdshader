shader_type canvas_item;
// 小王子伪星球 —— 鱼眼球面投影 Shader（sphere_fisheye）
//
// 原理：
//   1. world_tex 是整张 32×32 平面地图渲染出来的「可平铺」纹理
//      （sampler 开启 repeat_enable，配合 fract() 让 UV 在 0~1 之间无缝首尾相连）。
//   2. 屏幕上的每个像素先映射到以画面中心为原点的单位圆内，圆外直接
//      画成深空星野；圆内的点被当作「从外太空看向一颗小行星」时视线
//      落在球面上的位置：z = sqrt(1 - r^2) 是该点相对视线方向的深度，
//      acos(z) 则是它与球心（视线正对的那一点）之间的球面角距离。
//   3. 用这个角距离反推出在「地图纹理」上应该偏移多少 UV，再叠加玩家
//      当前所在的归一化坐标 player_uv，就得到最终采样坐标——这样无论
//      玩家走到地图哪里，球心永远对准玩家，效果等价于「相机永远跟随
//      小王子」，且完全没有传统摄像机在地图边缘会露出空白的问题。

// 世界贴图：由隐藏的 SubViewport 渲染整张地图 + 地物 + 小王子得到
uniform sampler2D world_tex : filter_linear, repeat_enable;
// 玩家在地图上的归一化坐标（0~1），即「球心对准的地方」
uniform vec2 player_uv = vec2(0.5, 0.5);
// 球面曲率：1.0 约等于标准正交半球投影；调大后边缘畸变更强、可视范围更广
uniform float curvature : hint_range(0.5, 3.0) = 1.55;
// 圆形画面边缘对应地图宽度的比例（可视范围），越大能看到越多地图内容
uniform float view_span : hint_range(0.05, 1.0) = 0.48;
// 深空背景色 & 星点密度
uniform vec3 space_color : source_color = vec3(0.015, 0.018, 0.055);
uniform float star_density : hint_range(0.0, 1.0) = 0.45;
// 星球边缘的大气辉光颜色
uniform vec3 rim_glow_color : source_color = vec3(0.45, 0.65, 1.0);

// 注意：PI / TAU 是 Godot Shading Language 的内置常量，不能再自行定义
const float HALF_PI = PI * 0.5;

// 简单哈希函数，用来在深空背景里撒星星
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	// 以画面中心为原点、并按视口宽高比修正的坐标，保证圆形不会被拉扁成椭圆
	float aspect = SCREEN_PIXEL_SIZE.y / max(SCREEN_PIXEL_SIZE.x, 0.0000001);
	vec2 p = (UV - 0.5) * 2.0;
	p.y *= aspect;
	float r = length(p);

	if (r > 1.0) {
		// 圆外：星空背景
		vec2 star_uv = floor(SCREEN_UV * 360.0);
		float star = step(0.9972, hash21(star_uv)) * star_density;
		float twinkle = 0.55 + 0.45 * hash21(star_uv + 17.0);
		COLOR = vec4(space_color + vec3(star * twinkle), 1.0);
	} else {
		// 正交投影下的球面深度与角距离（鱼眼效果的数学核心）
		float z = sqrt(max(0.0, 1.0 - r * r));
		float angle = acos(clamp(z, -1.0, 1.0)) * curvature;
		vec2 dir = (r > 0.0001) ? (p / r) : vec2(0.0);
		vec2 offset = dir * (angle / HALF_PI) * (view_span * 0.5);

		// player_uv 始终位于圆心（r=0 时 offset=0），实现「相机永远跟随玩家」；
		// fract() 让地图在纹理坐标上无缝环绕，对应逻辑世界的首尾相连
		vec2 sample_uv = fract(player_uv + offset);
		vec4 tex_color = texture(world_tex, sample_uv);

		// 球面明暗：中心更亮，边缘更暗，增强立体感
		float shade = mix(0.52, 1.0, z);
		// 边缘大气辉光
		float rim = smoothstep(0.78, 1.0, r) * 0.5;
		// 柔和剪影边缘，避免硬锯齿
		float edge_aa = 1.0 - smoothstep(0.985, 1.0, r);

		vec3 final_rgb = tex_color.rgb * shade + rim_glow_color * rim;
		COLOR = vec4(final_rgb, edge_aa);
	}
}
