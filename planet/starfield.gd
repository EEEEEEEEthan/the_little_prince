class_name Starfield
extends Sprite2D
## 深空星野：贴图中心对齐球心，旋转 = 星球旋转 + 相对星球的自转。

## 星球旋转分量，由 Planet 同步写入。
var planet_rotation: float = 0.0
var _self_rotation: float = 0.0

func set_planet_rotation(value: float) -> void:
	planet_rotation = value
	rotation = planet_rotation + _self_rotation

func _process(delta: float) -> void:
	_self_rotation = fposmod(
		_self_rotation + WorldConstants.STAR_ROTATION_SPEED * delta, TAU
	)
	rotation = planet_rotation + _self_rotation
