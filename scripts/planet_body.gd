class_name PlanetBody
extends Node2D
## 星球实体：在本地原点画实心圆（沙色填充 + 岩边噪点）。
## Planet 节点本身位于球心，因此本节点 position 保持 (0,0)。

var radius: float = WorldConstants.PLANET_RADIUS

func _draw() -> void:
	var r: float = radius
	if r < 1.0:
		return
	# 主体沙色
	var sand := Color(0.86, 0.72, 0.42)
	draw_circle(Vector2.ZERO, r, sand)

	# 外缘略深的岩边环
	var rim := Color(0.55, 0.42, 0.30)
	var rim_w: float = max(3.0, r * 0.018)
	draw_arc(Vector2.ZERO, r - rim_w * 0.5, 0.0, TAU, 128, rim, rim_w, true)

	# 确定性噪点斑块：模拟沙漠纹理
	var spots: int = int(r * 0.35)
	for i in spots:
		var h1: float = _hash(i, 7)
		var h2: float = _hash(i, 19)
		var h3: float = _hash(i, 31)
		var ang: float = h1 * TAU
		var dist: float = sqrt(h2) * (r - rim_w * 2.0)
		var p := Vector2(cos(ang), sin(ang)) * dist
		var spot_r: float = lerpf(1.5, 4.5, h3) * (r / WorldConstants.PLANET_RADIUS)
		var c := sand.darkened(lerpf(0.04, 0.14, h3))
		c.a = 0.55
		draw_circle(p, spot_r, c)

	# 内部一圈浅阴影，增强球体体积感（仍是 2D 圆）
	var shade := Color(0.62, 0.48, 0.28, 0.18)
	draw_circle(Vector2(r * 0.12, r * 0.18), r * 0.72, shade)

static func _hash(i: int, salt: int) -> float:
	var n: float = sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453
	return n - floor(n)
