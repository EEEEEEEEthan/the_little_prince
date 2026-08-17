class_name PixelArt
extends RefCounted
## 纯代码程序化像素画生成器。
##
## 项目不依赖任何外部美术资源：所有贴图（地表、火山、猴面包树、
## 玫瑰、小王子本人）均由本类在运行时用 Image 逐像素绘制并封装为
## ImageTexture。一眼可辨认，且仓库无需二进制美术文件。

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

## ---------- 地表贴图 ----------

## 沙地：暖黄色基调 + 细颗粒噪点（小王子星球的沙漠地表）
static func make_sand_tile(size: int) -> ImageTexture:
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
	return ImageTexture.create_from_image(img)

## 岩地：冷灰褐色基调 + 粗颗粒噪点，用作裸露岩石地带
static func make_rock_tile(size: int) -> ImageTexture:
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
	return ImageTexture.create_from_image(img)

## ---------- 地物贴图（侧视单图，兼容旧调用） ----------

## 火山：锥形山体 + 火山口 + 岩浆微光 + 一缕青烟
static func make_volcano_sprite(size: int) -> ImageTexture:
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
	return ImageTexture.create_from_image(img)

## 猴面包树：极粗的树干 + 顶端稀疏树冠（《小王子》里标志性的「胖树」造型）
static func make_baobab_sprite(size: int) -> ImageTexture:
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
	return ImageTexture.create_from_image(img)

## 玫瑰：唯一的一朵，六片花瓣环绕花心 + 细茎与两片小叶
static func make_rose_sprite(size: int) -> ImageTexture:
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
	return ImageTexture.create_from_image(img)

## ---------- 地物高度切片（俯视截面，底→顶，供 StackedProp 使用） ----------

## 猴面包树切片：底部粗树干椭圆 → 中段树干 → 顶层树冠团块
static func make_baobab_layers(size: int, layer_count: int = WorldConstants.BAOBAB_LAYER_COUNT) -> Array[Texture2D]:
	var layers: Array[Texture2D] = []
	var cx: float = size * 0.5
	var cy: float = size * 0.5
	var trunk := Color(0.4, 0.28, 0.16)
	var canopy_a := Color(0.18, 0.35, 0.16)
	var canopy_b := Color(0.24, 0.42, 0.2)
	var last: int = maxi(layer_count - 1, 1)

	for i in layer_count:
		var img := _new_image(size)
		var t: float = float(i) / float(last)
		if t < 0.45:
			# 底部粗干：椭圆截面略扁，随高度略收
			var local_t: float = t / 0.45
			var rx: float = lerpf(size * 0.28, size * 0.2, local_t)
			var ry: float = lerpf(size * 0.22, size * 0.16, local_t)
			var c := trunk.darkened(local_t * 0.08)
			_fill_ellipse(img, Vector2(cx, cy), rx, ry, c)
			_fill_ellipse(img, Vector2(cx, cy), rx * 0.55, ry * 0.55, c.lightened(0.08))
			# 树皮竖纹噪点
			for y in range(int(cy - ry), int(cy + ry) + 1):
				for x in range(int(cx - rx), int(cx + rx) + 1):
					if _hash(x, y, 41) > 0.72 and img.get_pixel(x, y).a > 0.1:
						_blend_px(img, x, y, Color(0, 0, 0, 0.18))
		elif t < 0.62:
			# 中段：稍细树干 + 分叉起点
			var rx2: float = size * 0.16
			var ry2: float = size * 0.13
			_fill_ellipse(img, Vector2(cx, cy), rx2, ry2, trunk.darkened(0.05))
			_fill_ellipse(img, Vector2(cx - size * 0.1, cy - size * 0.04), size * 0.08, size * 0.06, trunk)
			_fill_ellipse(img, Vector2(cx + size * 0.11, cy - size * 0.02), size * 0.08, size * 0.06, trunk)
		else:
			# 顶层树冠：几团绿叶（标志性「胖伞」）
			var canopy_t: float = (t - 0.62) / 0.38
			var blobs: Array[Vector2] = [
				Vector2(cx - size * 0.16, cy + size * 0.02),
				Vector2(cx, cy - size * 0.08),
				Vector2(cx + size * 0.18, cy + size * 0.04),
				Vector2(cx - size * 0.04, cy + size * 0.12),
			]
			var scale: float = lerpf(0.7, 1.05, canopy_t)
			for bi in blobs.size():
				var tip: Vector2 = blobs[bi]
				var col := canopy_a if bi % 2 == 0 else canopy_b
				_fill_ellipse(img, tip, size * 0.14 * scale, size * 0.11 * scale, col)
				_fill_ellipse(
					img,
					tip + Vector2(0, -size * 0.03),
					size * 0.08 * scale,
					size * 0.06 * scale,
					col.lightened(0.12)
				)
			# 中央仍露一点枝丫
			if canopy_t < 0.35:
				_fill_ellipse(img, Vector2(cx, cy), size * 0.07, size * 0.06, trunk.darkened(0.1))
		layers.append(ImageTexture.create_from_image(img))
	return layers

## 火山切片：底部宽锥底向上收窄，顶层火山口 + 岩浆；若干侧层保留岩浆流
static func make_volcano_layers(size: int, layer_count: int = WorldConstants.VOLCANO_LAYER_COUNT) -> Array[Texture2D]:
	var layers: Array[Texture2D] = []
	var cx: float = size * 0.5
	var cy: float = size * 0.5
	var rock_a := Color(0.42, 0.2, 0.15)
	var rock_b := Color(0.24, 0.11, 0.09)
	var lava := Color(0.95, 0.42, 0.08)
	var lava_hot := Color(1.0, 0.85, 0.25)
	var crater := Color(0.12, 0.07, 0.06)
	var last: int = maxi(layer_count - 1, 1)

	for i in layer_count:
		var img := _new_image(size)
		var t: float = float(i) / float(last)
		# 锥体半径：底宽顶窄
		var rx: float = lerpf(size * 0.42, size * 0.12, pow(t, 0.75))
		var ry: float = lerpf(size * 0.36, size * 0.1, pow(t, 0.75))
		var slope := rock_a.lerp(rock_b, t)

		_fill_ellipse(img, Vector2(cx, cy), rx, ry, slope)
		# 边缘加暗一圈
		_fill_ellipse(img, Vector2(cx, cy), rx * 0.92, ry * 0.92, slope.lightened(0.04))
		for y in range(int(cy - ry), int(cy + ry) + 1):
			for x in range(int(cx - rx), int(cx + rx) + 1):
				var dx: float = (x + 0.5 - cx) / max(rx, 0.0001)
				var dy: float = (y + 0.5 - cy) / max(ry, 0.0001)
				var r2: float = dx * dx + dy * dy
				if r2 <= 1.0 and r2 > 0.82:
					_blend_px(img, x, y, Color(0, 0, 0, 0.28))
				elif r2 <= 1.0 and _hash(x, y, 3) > 0.78:
					_blend_px(img, x, y, Color(0, 0, 0, 0.12))

		# 中上层：岩浆流（偏右下，与侧视图一致）
		if t > 0.25 and t < 0.78:
			var flow_from := Vector2(cx + rx * 0.15, cy)
			var flow_to := Vector2(cx + rx * 0.85, cy + ry * 0.55)
			_stroke_line(img, flow_from, flow_to, max(1.2, size * 0.04 * (1.0 - t)), Color(0.9, 0.35, 0.05, 0.8))

		# 顶层：火山口 + 岩浆池
		if t > 0.72:
			var crater_t: float = (t - 0.72) / 0.28
			var crx: float = lerpf(rx * 0.85, rx * 1.05, crater_t)
			var cry: float = lerpf(ry * 0.7, ry * 0.9, crater_t)
			_fill_ellipse(img, Vector2(cx, cy), crx, cry, crater)
			_fill_ellipse(img, Vector2(cx, cy), crx * 0.65, cry * 0.55, lava)
			_fill_ellipse(img, Vector2(cx, cy - cry * 0.1), crx * 0.28, cry * 0.22, lava_hot)
			# 顶层一点青烟暗示
			if crater_t > 0.6:
				_fill_ellipse(
					img,
					Vector2(cx - size * 0.02, cy - ry * 0.15),
					size * 0.06,
					size * 0.04,
					Color(0.75, 0.78, 0.8, 0.3)
				)
		layers.append(ImageTexture.create_from_image(img))
	return layers

## 玫瑰切片：茎截面 → 叶 → 花瓣环 → 花心
static func make_rose_layers(size: int, layer_count: int = WorldConstants.ROSE_LAYER_COUNT) -> Array[Texture2D]:
	var layers: Array[Texture2D] = []
	var cx: float = size * 0.5
	var cy: float = size * 0.5
	var stem := Color(0.2, 0.45, 0.18)
	var leaf := Color(0.22, 0.5, 0.2)
	var petal_a := Color(0.85, 0.18, 0.32)
	var petal_b := Color(0.92, 0.32, 0.42)
	var heart := Color(0.6, 0.08, 0.18)
	var tip := Color(0.98, 0.75, 0.35)
	var last: int = maxi(layer_count - 1, 1)

	for i in layer_count:
		var img := _new_image(size)
		var t: float = float(i) / float(last)
		if t < 0.28:
			# 茎：小圆截面
			var r: float = lerpf(size * 0.08, size * 0.06, t / 0.28)
			_fill_ellipse(img, Vector2(cx, cy), r, r, stem)
		elif t < 0.5:
			# 叶：两侧小椭圆
			_fill_ellipse(img, Vector2(cx, cy), size * 0.05, size * 0.05, stem)
			_fill_ellipse(img, Vector2(cx - size * 0.16, cy), size * 0.14, size * 0.07, leaf)
			_fill_ellipse(img, Vector2(cx + size * 0.16, cy + size * 0.04), size * 0.14, size * 0.07, leaf.lightened(0.05))
		elif t < 0.85:
			# 花瓣环：六片俯视
			var bloom_t: float = (t - 0.5) / 0.35
			var petal_r: float = lerpf(size * 0.12, size * 0.18, bloom_t)
			var ring: float = lerpf(size * 0.08, size * 0.13, bloom_t)
			for pi in range(6):
				var angle: float = TAU * float(pi) / 6.0
				var petal_pos: Vector2 = Vector2(cx, cy) + Vector2(cos(angle), sin(angle)) * ring
				var col := petal_a if pi % 2 == 0 else petal_b
				_fill_ellipse(img, petal_pos, petal_r, petal_r * 0.8, col)
			_fill_ellipse(img, Vector2(cx, cy), size * 0.07, size * 0.07, heart)
		else:
			# 花心高光
			_fill_ellipse(img, Vector2(cx, cy), size * 0.1, size * 0.1, heart)
			_fill_ellipse(img, Vector2(cx, cy - size * 0.02), size * 0.045, size * 0.045, tip)
			# 仍留一圈薄花瓣边缘
			for pi in range(6):
				var angle2: float = TAU * float(pi) / 6.0 + 0.2
				var p2: Vector2 = Vector2(cx, cy) + Vector2(cos(angle2), sin(angle2)) * size * 0.1
				_fill_ellipse(img, p2, size * 0.08, size * 0.06, petal_a if pi % 2 == 0 else petal_b)
		layers.append(ImageTexture.create_from_image(img))
	return layers

## 小王子：金色卷发 + 绿色大衣剪影，简洁可辨认
static func make_player_sprite(width: int, height: int) -> ImageTexture:
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
	return ImageTexture.create_from_image(img)
