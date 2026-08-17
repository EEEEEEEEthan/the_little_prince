class_name PixelArt
extends RefCounted
## 程序化像素画生成器（导出工具用）。
##
## 游戏运行时贴图已静态化为 player/ 与 planet/ 下的 PNG，
## 由场景 tscn 或 SurfaceProp / Player / Starfield preload 加载。
## 本类保留算法，供 tools/export_static_assets.gd 生成 PNG；
## 运行时路径不应再调用 make_*。

## ---------- 基础绘制工具 ----------

static func _new_image(size: int) -> Image:
	return Image.create(size, size, false, Image.FORMAT_RGBA8)

## 基于坐标的确定性伪随机（正弦哈希），用来给纯色块加自然噪点。
static func _hash(x: int, y: int, salt: int) -> float:
	var n: float = sin(float(x) * 12.9898 + float(y) * 78.233 + float(salt) * 37.719) * 43758.5453
	return n - floor(n)

static func _set_px(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, color)

static func _blend_px(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	var below: Color = img.get_pixel(x, y)
	img.set_pixel(x, y, below.blend(color))

static func _fill_ellipse(img: Image, center: Vector2, rx: float, ry: float, color: Color) -> void:
	var min_x: int = int(floor(center.x - rx))
	var max_x: int = int(ceil(center.x + rx))
	var min_y: int = int(floor(center.y - ry))
	var max_y: int = int(ceil(center.y + ry))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var dx: float = (x + 0.5 - center.x) / max(rx, 0.0001)
			var dy: float = (y + 0.5 - center.y) / max(ry, 0.0001)
			if dx * dx + dy * dy <= 1.0:
				_blend_px(img, x, y, color)

static func _stroke_line(img: Image, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var dist: float = from.distance_to(to)
	var steps: int = max(1, int(ceil(dist * 2.0)))
	for i in range(steps + 1):
		var p: Vector2 = from.lerp(to, float(i) / float(steps))
		_fill_ellipse(img, p, width * 0.5, width * 0.5, color)

static func _to_texture(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

## ---------- 地表 / 星球 / 星野 Image（导出用） ----------

## 沙地：暖黄色基调 + 细颗粒噪点
static func build_sand_tile(size: int) -> Image:
	var img := _new_image(size)
	var base := Color(0.86, 0.72, 0.42)
	for y in size:
		for x in size:
			var n: float = _hash(x, y, 11)
			var c := base
			c.r += (n - 0.5) * 0.08
			c.g += (n - 0.5) * 0.07
			c.b += (n - 0.5) * 0.05
			c.a = 1.0
			img.set_pixel(x, y, c)
	return img

## 岩地：冷灰褐色基调 + 粗颗粒噪点
static func build_rock_tile(size: int) -> Image:
	var img := _new_image(size)
	var base := Color(0.5, 0.46, 0.43)
	for y in size:
		for x in size:
			var n: float = _hash(x, y, 29)
			var c := base
			c.r += (n - 0.5) * 0.14
			c.g += (n - 0.5) * 0.12
			c.b += (n - 0.5) * 0.12
			c.a = 1.0
			img.set_pixel(x, y, c)
	return img

## 完整星球圆盘：沙色填充 + 岩边 + 噪点斑块（静态贴图，替换旧逐帧 _draw）
static func build_planet_body(radius: float) -> Image:
	var r: int = max(1, int(ceil(radius)))
	var size: int = r * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: float = float(r) - 0.5
	var cy: float = float(r) - 0.5
	var sand := Color(0.86, 0.72, 0.42)
	var rim := Color(0.55, 0.42, 0.30)
	var rim_w: float = max(2.0, float(r) * 0.018)
	var rf: float = float(r)

	for y in size:
		for x in size:
			var dx: float = (x + 0.5) - cx
			var dy: float = (y + 0.5) - cy
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist > rf:
				continue
			var c := sand
			# 岩边环
			if dist >= rf - rim_w:
				c = rim
			else:
				# 确定性噪点
				var n: float = _hash(x, y, 7)
				c.r += (n - 0.5) * 0.06
				c.g += (n - 0.5) * 0.05
				c.b += (n - 0.5) * 0.04
				# 内部浅阴影增强体积感
				var shade_dx: float = (x + 0.5) - (cx + rf * 0.12)
				var shade_dy: float = (y + 0.5) - (cy + rf * 0.18)
				var shade_d: float = sqrt(shade_dx * shade_dx + shade_dy * shade_dy)
				if shade_d < rf * 0.72:
					c = c.lerp(Color(0.62, 0.48, 0.28), 0.18)
			c.a = 1.0
			img.set_pixel(x, y, c)

	# 额外斑块（与旧 _draw 观感接近）
	var spots: int = int(rf * 0.35)
	for i in spots:
		var h1: float = _hash(i, 0, 7)
		var h2: float = _hash(i, 1, 19)
		var h3: float = _hash(i, 2, 31)
		var ang: float = h1 * TAU
		var dist: float = sqrt(h2) * (rf - rim_w * 2.0)
		var px: int = int(round(cx + cos(ang) * dist))
		var py: int = int(round(cy + sin(ang) * dist))
		var spot_r: float = lerpf(1.0, 3.0, h3)
		var spot_c := sand.darkened(lerpf(0.04, 0.14, h3))
		spot_c.a = 0.55
		_fill_ellipse(img, Vector2(px, py), spot_r, spot_r, spot_c)
	return img

## 深空星野：按密度铺星（约 1 颗/717px²），任意尺寸下视口内星密度一致
static func build_starfield(width: int, height: int) -> Image:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var bg := Color(0.015, 0.018, 0.055)
	img.fill(bg)
	var count: int = int(float(width * height) / 717.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	for i in count:
		var sx: int = int(rng.randf() * float(width))
		var sy: int = int(rng.randf() * float(height))
		var b: float = rng.randf_range(0.35, 1.0)
		var c := Color(0.85 * b, 0.88 * b, 1.0 * b, 0.9)
		_set_px(img, sx, sy, c)
		# 略亮的星多画一像素，接近旧 1.5×1.5 点
		if b > 0.7:
			_set_px(img, sx + 1, sy, c)
	return img

## ---------- 地物 Image（导出用） ----------

static func build_volcano_sprite(size: int) -> Image:
	var img := _new_image(size)
	var cx: float = size * 0.5
	var top_y: float = size * 0.22
	var base_y: float = size * 0.86
	var top_half: float = size * 0.07
	var base_half: float = size * 0.38

	for y in range(int(top_y), int(base_y) + 1):
		var t: float = (y - top_y) / max(base_y - top_y, 1.0)
		var half_w: float = lerpf(top_half, base_half, pow(t, 0.8))
		var slope_color := Color(0.42, 0.2, 0.15).lerp(Color(0.24, 0.11, 0.09), t)
		for x in range(int(cx - half_w), int(cx + half_w) + 1):
			var n: float = _hash(x, y, 3)
			var c := slope_color
			c.r += (n - 0.5) * 0.05
			c.g += (n - 0.5) * 0.04
			c.b += (n - 0.5) * 0.03
			if absf(float(x) - (cx - half_w)) < 1.0 or absf(float(x) - (cx + half_w)) < 1.0:
				c = c.darkened(0.35)
			c.a = 1.0
			img.set_pixel(x, y, c)

	_fill_ellipse(img, Vector2(cx, top_y + 1.0), top_half * 1.1, top_half * 0.55, Color(0.12, 0.07, 0.06))
	_fill_ellipse(img, Vector2(cx, top_y + 1.6), top_half * 0.7, top_half * 0.35, Color(0.95, 0.42, 0.08, 0.9))
	_fill_ellipse(img, Vector2(cx, top_y + 1.6), top_half * 0.32, top_half * 0.18, Color(1.0, 0.85, 0.25))
	_stroke_line(
		img,
		Vector2(cx + top_half * 0.4, top_y + 2.0),
		Vector2(cx + base_half * 0.45, base_y - 3.0),
		1.4,
		Color(0.9, 0.35, 0.05, 0.75)
	)
	_fill_ellipse(img, Vector2(cx - 1.0, top_y - 3.0), size * 0.09, size * 0.06, Color(0.75, 0.78, 0.8, 0.35))
	_fill_ellipse(img, Vector2(cx + 2.0, top_y - 6.0), size * 0.07, size * 0.05, Color(0.8, 0.82, 0.85, 0.22))
	return img

static func build_baobab_sprite(size: int) -> Image:
	var img := _new_image(size)
	var cx: float = size * 0.5
	var trunk_top: float = size * 0.42
	var trunk_bottom: float = size * 0.92

	for y in range(int(trunk_top), int(trunk_bottom) + 1):
		var t: float = (y - trunk_top) / max(trunk_bottom - trunk_top, 1.0)
		var half_w: float = lerpf(size * 0.14, size * 0.2, t)
		var trunk_color := Color(0.4, 0.28, 0.16).darkened(t * 0.15)
		for x in range(int(cx - half_w), int(cx + half_w) + 1):
			var n: float = _hash(x, y, 41)
			var c := trunk_color
			c.r += (n - 0.5) * 0.05
			c.g += (n - 0.5) * 0.04
			c.b += (n - 0.5) * 0.03
			if int(x - cx + half_w) % 4 == 0:
				c = c.darkened(0.2)
			c.a = 1.0
			img.set_pixel(x, y, c)

	var branch_tips: Array[Vector2] = [
		Vector2(cx - size * 0.22, trunk_top - size * 0.14),
		Vector2(cx, trunk_top - size * 0.2),
		Vector2(cx + size * 0.24, trunk_top - size * 0.12),
		Vector2(cx - size * 0.08, trunk_top - size * 0.22),
	]
	for tip in branch_tips:
		_stroke_line(img, Vector2(cx, trunk_top), tip, size * 0.06, Color(0.35, 0.24, 0.14))
		_fill_ellipse(img, tip, size * 0.13, size * 0.1, Color(0.18, 0.35, 0.16))
		_fill_ellipse(img, tip + Vector2(0, -size * 0.03), size * 0.08, size * 0.06, Color(0.24, 0.42, 0.2))
	return img

static func build_rose_sprite(size: int) -> Image:
	var img := _new_image(size)
	var cx: float = size * 0.5
	var stem_top: float = size * 0.42
	var stem_bottom: float = size * 0.96

	_stroke_line(img, Vector2(cx, stem_top), Vector2(cx, stem_bottom), size * 0.06, Color(0.2, 0.45, 0.18))
	_fill_ellipse(img, Vector2(cx - size * 0.16, stem_top + size * 0.24), size * 0.14, size * 0.07, Color(0.22, 0.5, 0.2))
	_fill_ellipse(img, Vector2(cx + size * 0.16, stem_top + size * 0.34), size * 0.14, size * 0.07, Color(0.24, 0.52, 0.21))

	var bloom_center := Vector2(cx, stem_top - size * 0.02)
	var petal_r: float = size * 0.16
	for i in range(6):
		var angle: float = TAU * float(i) / 6.0
		var petal_pos: Vector2 = bloom_center + Vector2(cos(angle), sin(angle)) * size * 0.12
		var petal_color := Color(0.85, 0.18, 0.32) if i % 2 == 0 else Color(0.92, 0.32, 0.42)
		_fill_ellipse(img, petal_pos, petal_r, petal_r * 0.8, petal_color)
	_fill_ellipse(img, bloom_center, size * 0.09, size * 0.09, Color(0.6, 0.08, 0.18))
	_fill_ellipse(img, bloom_center - Vector2(0, size * 0.02), size * 0.04, size * 0.04, Color(0.98, 0.75, 0.35))
	return img

static func build_player_sprite(width: int, height: int) -> Image:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var cx: float = width * 0.5
	var skin := Color(0.96, 0.8, 0.64)
	var hair := Color(0.95, 0.78, 0.25)
	var coat := Color(0.16, 0.45, 0.27)
	var scarf := Color(0.86, 0.55, 0.14)

	var head_center := Vector2(cx, height * 0.24)
	var head_r: float = width * 0.24
	_fill_ellipse(img, head_center, head_r, head_r, skin)
	_fill_ellipse(img, head_center + Vector2(0, -head_r * 0.7), head_r * 0.95, head_r * 0.6, hair)
	_fill_ellipse(img, head_center + Vector2(-head_r * 0.9, -head_r * 0.1), head_r * 0.5, head_r * 0.55, hair)
	_fill_ellipse(img, head_center + Vector2(head_r * 0.9, -head_r * 0.1), head_r * 0.5, head_r * 0.55, hair)

	var coat_top: float = height * 0.42
	var coat_bottom: float = height * 0.92
	for y in range(int(coat_top), int(coat_bottom) + 1):
		var t: float = (y - coat_top) / max(coat_bottom - coat_top, 1.0)
		var half_w: float = lerpf(width * 0.16, width * 0.3, t)
		for x in range(int(cx - half_w), int(cx + half_w) + 1):
			_blend_px(img, x, y, coat)
	_fill_ellipse(img, Vector2(cx, coat_top + 1.0), width * 0.2, height * 0.035, scarf)
	_fill_ellipse(img, Vector2(cx - width * 0.12, coat_bottom - 1.0), width * 0.08, height * 0.03, Color(0.22, 0.18, 0.14))
	_fill_ellipse(img, Vector2(cx + width * 0.12, coat_bottom - 1.0), width * 0.08, height * 0.03, Color(0.22, 0.18, 0.14))
	return img

## ---------- Texture 包装（仅导出脚本 / 可选测试；运行时勿用） ----------

static func make_sand_tile(size: int) -> ImageTexture:
	return _to_texture(build_sand_tile(size))

static func make_rock_tile(size: int) -> ImageTexture:
	return _to_texture(build_rock_tile(size))

static func make_volcano_sprite(size: int) -> ImageTexture:
	return _to_texture(build_volcano_sprite(size))

static func make_baobab_sprite(size: int) -> ImageTexture:
	return _to_texture(build_baobab_sprite(size))

static func make_rose_sprite(size: int) -> ImageTexture:
	return _to_texture(build_rose_sprite(size))

static func make_player_sprite(width: int, height: int) -> ImageTexture:
	return _to_texture(build_player_sprite(width, height))

static func make_planet_body(radius: float) -> ImageTexture:
	return _to_texture(build_planet_body(radius))

static func make_starfield(width: int, height: int) -> ImageTexture:
	return _to_texture(build_starfield(width, height))
