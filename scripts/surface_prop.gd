class_name SurfaceProp
extends Node2D
## 圆弧星球上的地表地物：玫瑰 / 火山 / 猴面包树。
##
## 局部坐标以球心为原点：
##   position = Vector2(sin(α), -cos(α)) * radius
##   rotation  = α
## 精灵脚底贴地（offset 把贴图底部对齐到圆周），头朝外、脚朝球心。

enum Kind { ROSE, VOLCANO, BAOBAB }

## 地物在星球上的绝对角（弧度）
var angle: float = 0.0
var kind: Kind = Kind.BAOBAB

var _sprite: Sprite2D
var _radius: float = WorldConstants.PLANET_RADIUS

func configure(p_kind: Kind, p_angle: float, radius: float) -> void:
	kind = p_kind
	angle = p_angle
	_radius = radius
	_ensure_sprite()
	_apply_texture()
	_place_on_surface()
	_apply_visual_scale()

func set_planet_radius(radius: float) -> void:
	_radius = radius
	_place_on_surface()
	_apply_visual_scale()

## 相对基准半径缩放，再乘 PROP_SCALE；窗口变化后地物相对星球仍协调
func _apply_visual_scale() -> void:
	var s: float = (_radius / WorldConstants.PLANET_RADIUS) * WorldConstants.PROP_SCALE
	scale = Vector2(s, s)

## 根据相对弧顶的角更新可见性与深度（相对角 = angle - player_angle）
func update_visibility(player_angle: float) -> void:
	var rel: float = angle_difference(player_angle, angle)
	var abs_rel: float = absf(rel)
	var on_front: bool = abs_rel <= WorldConstants.VISIBLE_HALF_ARC
	visible = on_front or WorldConstants.BACKFACE_ALPHA > 0.001
	if on_front:
		modulate = Color(1, 1, 1, 1)
	else:
		modulate = Color(1, 1, 1, WorldConstants.BACKFACE_ALPHA)
		if WorldConstants.BACKFACE_ALPHA <= 0.001:
			visible = false
	# 越靠近弧顶越靠前绘制；背面不参与排序
	z_index = int(cos(rel) * 100.0)

func _ensure_sprite() -> void:
	if _sprite != null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "精灵"
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

func _apply_texture() -> void:
	var tex: Texture2D
	match kind:
		Kind.ROSE:
			tex = PixelArt.make_rose_sprite(WorldConstants.SPRITE_ROSE)
			name = "玫瑰"
		Kind.VOLCANO:
			tex = PixelArt.make_volcano_sprite(WorldConstants.SPRITE_VOLCANO)
			name = "火山"
		Kind.BAOBAB:
			tex = PixelArt.make_baobab_sprite(WorldConstants.SPRITE_BAOBAB)
			name = "猴面包树"
	_sprite.texture = tex
	# 脚底贴地：把精灵中心上移半高，使贴图底部落在圆周上
	var h: float = float(tex.get_height())
	_sprite.offset = Vector2(0, -h * 0.5)

func _place_on_surface() -> void:
	# α=0 时在弧顶 (0, -radius)；脚朝球心、头朝外
	position = Vector2(sin(angle), -cos(angle)) * _radius
	rotation = angle
