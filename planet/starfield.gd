class_name Starfield
extends Node2D
## 天空背景：白昼图(day_sky)是黑红渐变 mask，shader 从天顶/地平线渐变
## 按星空相对角度（相位）与高度换色；夜图(starfield)按相位从
## night_sky_gradient 渐变取透明度，覆盖其上实现昼夜更替。
## 整体绕球心旋转 = 星球旋转 + 相对星球的自转；白昼天空固定在星空正上方，
## 镜头朝上，故相对角度即本节点 rotation。

@export var night_sky_gradient: GradientTexture1D

@onready var night_sky: Sprite2D = $NightSky
@onready var _day_sky_material: ShaderMaterial = $DaySky.material

## 星球旋转分量，由 Planet 同步写入。
var planet_rotation: float = 0.0
var _self_rotation: float = 0.0

func set_planet_rotation(value: float) -> void:
	planet_rotation = value
	rotation = planet_rotation + _self_rotation

func _process(delta: float) -> void:
	_self_rotation = fposmod(
		_self_rotation - WorldConstants.STAR_ROTATION_SPEED * delta, TAU
	)
	rotation = planet_rotation + _self_rotation
	_update_daylight()

## 昼夜混合：白天天空按相位从天顶/地平线渐变取渐变色；
## NightSky 透明度按同一相位从 night_sky_gradient 渐变采样
## （0=午夜不透明、0.25/0.5=白天透明、0.75=夜晚不透明、1=午夜）。
func _update_daylight() -> void:
	var phase := SkyPhase.angle_to_phase(rotation)
	_day_sky_material.set_shader_parameter("phase", phase)
	night_sky.modulate.a = night_sky_gradient.gradient.sample(phase).r
