class_name Starfield
extends Node2D
## 天空背景：白天(day_sky) 与黑夜(starfield) 两张贴图按镜头与星空的相对角度混合。
## 整体绕球心旋转 = 星球旋转 + 相对星球的自转；白昼天空固定在星空正上方，
## 镜头朝上，故相对角度即本节点 rotation，用余弦平滑映射为昼夜混合量。

@onready var day_sky: Sprite2D = $DaySky
@onready var night_sky: Sprite2D = $NightSky

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
	_update_daylight()

## 昼夜混合：rotation=0 时白昼天空正对镜头（正午），rotation=π 时背对（午夜，黑夜）。
## 夜图覆盖在白昼图之上，透明度随角度平滑过渡。
func _update_daylight() -> void:
	var daylight := (cos(rotation) + 1.0) * 0.5
	night_sky.modulate.a = 1.0 - daylight
