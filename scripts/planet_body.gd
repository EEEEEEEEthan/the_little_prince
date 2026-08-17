class_name PlanetBody
extends Sprite2D
## 星球实体：显示 assets/planet/body.png 静态圆盘（沙色 + 岩边 + 噪点）。
## Planet 节点位于球心，本节点 position 保持 (0,0)，随 Body.rotation 旋转。

## 当前半径（内部坐标系下通常等于 WorldConstants.PLANET_RADIUS）
var radius: float = WorldConstants.PLANET_RADIUS

const _BODY_TEX: Texture2D = preload("res://assets/planet/body.png")

func _ready() -> void:
	texture = _BODY_TEX
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_radius_scale()

func set_radius(value: float) -> void:
	radius = value
	_apply_radius_scale()

func _apply_radius_scale() -> void:
	if texture == null:
		return
	# 贴图直径应对齐 2 * PLANET_RADIUS；按当前半径缩放
	var half: float = float(texture.get_width()) * 0.5
	if half < 0.5:
		return
	var s: float = radius / half
	scale = Vector2(s, s)
