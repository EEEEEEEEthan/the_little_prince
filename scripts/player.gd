class_name Player
extends Node2D
## 小王子：左右输入驱动星球角；改角后立刻通知 Planet（同帧无延迟）。
## 屏幕位置钉在弧顶（planet_center + (0, -radius)），地表/本体绕球心旋转。
## 贴图：assets/sprites/prince.png（静态 preload，不运行时生成）。

## 当前站立角（弧度，绕球心；fposmod 到 [0, TAU)）
var angle: float = 0.0
## 当前星球半径（内部视口固定后通常等于常量）
var planet_radius: float = WorldConstants.PLANET_RADIUS
## 由 Main 注入；改角后立刻同步旋转
var planet: Planet = null

const _PRINCE_TEX: Texture2D = preload("res://assets/sprites/prince.png")

var _sprite: Sprite2D

func _ready() -> void:
	InputSetup.ensure_move_actions()
	_sprite = Sprite2D.new()
	_sprite.name = "小王子精灵"
	_sprite.texture = _PRINCE_TEX
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# 脚底贴地：贴图底部对齐弧顶
	var h: float = float(_sprite.texture.get_height())
	_sprite.offset = Vector2(0, -h * 0.5)
	_sprite.z_index = 200
	add_child(_sprite)
	z_index = 200
	_apply_visual_scale()

func _physics_process(delta: float) -> void:
	var input_x: float = (
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	)
	if is_zero_approx(input_x):
		return
	var angular_speed: float = WorldConstants.PLAYER_SPEED / max(planet_radius, 1.0)
	angle = fposmod(angle + input_x * angular_speed * delta, TAU)
	# 改角后立刻通知，避免 Main 先跑导致慢一帧
	_notify_planet()

## 同步半径并按基准半径缩放精灵
func set_planet_radius(radius: float) -> void:
	planet_radius = radius
	_apply_visual_scale()

func _apply_visual_scale() -> void:
	var s: float = (planet_radius / WorldConstants.PLANET_RADIUS) * WorldConstants.PLAYER_SCALE
	scale = Vector2(s, s)

## 把脚底放到弧顶世界坐标
func place_at_apex(apex: Vector2) -> void:
	global_position = apex

## 写入角度并立刻驱动星球旋转 + 钉在弧顶
func set_angle_and_sync(new_angle: float) -> void:
	angle = fposmod(new_angle, TAU)
	_notify_planet()

func _notify_planet() -> void:
	if planet == null:
		return
	planet.set_player_angle(angle)
	place_at_apex(planet.apex_global_position())
