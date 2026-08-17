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
//
// 正圆保证：view_size 由 Main 传入 PlanetView 的实际像素尺寸；
// 按较短边归一化，使单位圆在任意宽高比窗口下仍是视觉正圆。

// 世界贴图：由隐藏的 SubViewport 渲染整张地图 + 地物 + 小王子得到
uniform sampler2D world_tex : filter_nearest, repeat_enable;
// 玩家在地图上的归一化坐标（0~1），即「球心对准的地方」
uniform vec2 player_uv = vec2(0.5, 0.5);
// PlanetView 实际像素尺寸（由 main.gd 每帧写入）
uniform vec2 view_size = vec2(1.0, 1.0);
// 球面曲率：1.0 约等于标准正交半球投影；调大后边缘畸变更强、可视范围更广
uniform float curvature : hint_range(0.5, 3.0) = 1.55;
// 圆形画面边缘对应地图宽度的比例（可视范围），越大能看到越多地图内容
uniform float view_span : hint_range(0.05, 1.0) = 0.48;
// 深空背景色 & 星点密度
uniform vec3 space_color : source_color = vec3(0.015, 0.018, 0.055);
uniform float star_density : hint_range(0.0, 1.0) = 0.45;

// 注意：PI / TAU 是 Godot Shading Language 的内置常量，不能再自行定义
const float HALF_PI = PI * 0.5;

// 简单哈希函数，用来在深空背景里撒星星
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	// 以画面中心为原点，按 PlanetView 真实像素宽高比归一化：
	// 较短边映射到 [-1, 1]，较长边按比例拉长，单位圆 = 视觉正圆
	vec2 size = max(view_size, vec2(1.0));
	float min_side = min(size.x, size.y);
	vec2 p = (UV - 0.5) * 2.0;
	p.x *= size.x / min_side;
	p.y *= size.y / min_side;
	float r = length(p);

	if (r > 1.0) {
		// 圆外：星空背景
		vec2 star_uv = floor(UV * max(size.x, size.y) * 0.45);
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

		// 轻微球面明暗（中心略亮），无边缘辉光
		float shade = mix(0.72, 1.0, z);
		// 极窄抗锯齿，不改变正圆观感
		float edge_aa = 1.0 - smoothstep(0.992, 1.0, r);

		COLOR = vec4(tex_color.rgb * shade, edge_aa);
	}
}
