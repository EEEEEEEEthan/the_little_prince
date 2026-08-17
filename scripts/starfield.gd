class_name Starfield
extends Sprite2D
## 深空星野：作为 Planet 子节点，贴图中心对齐球心（position 保持 (0,0)）。
## 旋转 = 星球旋转（随玩家角 -player_angle）+ 相对星球的自转（缓慢持续）。

const _STAR_TEX: Texture2D = preload("res://assets/bg/starfield.png")

## 星球旋转分量（由 Planet 写入，随玩家角变化）
var planet_rotation: float = 0.0

var _self_rotation: float = 0.0

func _ready() -> void:
	z_index = -100
	texture = _STAR_TEX
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func set_planet_rotation(rot: float) -> void:
	planet_rotation = rot
	_apply_rotation()

func _process(delta: float) -> void:
	_self_rotation = fposmod(_self_rotation + WorldConstants.STAR_ROTATION_SPEED * delta, TAU)
	_apply_rotation()

func _apply_rotation() -> void:
	rotation = planet_rotation + _self_rotation
