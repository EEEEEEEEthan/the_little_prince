class_name Starfield
extends Node2D
## 深空星野背景：随窗口尺寸重绘，铺满整个视口。

var _viewport_size: Vector2 = Vector2(960, 960)
var _stars: PackedVector2Array = PackedVector2Array()
var _star_brightness: PackedFloat32Array = PackedFloat32Array()

func _ready() -> void:
	z_index = -100
	_rebuild(get_viewport_rect().size)

func set_viewport_size(size: Vector2) -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	if size.is_equal_approx(_viewport_size):
		return
	_rebuild(size)

func _rebuild(size: Vector2) -> void:
	_viewport_size = size
	_stars.clear()
	_star_brightness.clear()
	var count: int = int(clampf(size.x * size.y / 2800.0, 80.0, 260.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	for i in count:
		_stars.append(Vector2(rng.randf() * size.x, rng.randf() * size.y))
		_star_brightness.append(rng.randf_range(0.35, 1.0))
	queue_redraw()

func _draw() -> void:
	# 深空底色
	draw_rect(Rect2(Vector2.ZERO, _viewport_size), Color(0.015, 0.018, 0.055), true)
	# 稀疏星点
	for i in _stars.size():
		var b: float = _star_brightness[i]
		var c := Color(0.85 * b, 0.88 * b, 1.0 * b, 0.9)
		draw_rect(Rect2(_stars[i], Vector2(1.5, 1.5)), c, true)
