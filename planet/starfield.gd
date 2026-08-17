class_name Starfield
extends Node2D
## 天空背景：白昼图(day_sky)为黑红渐变，shader 按星空相对角度所处的时段
## （正午/夕阳/午夜/朝霞）把红色替换为真实天空渐变色；
## 夜图(starfield)覆盖其上，按角度余弦混合实现昼夜更替。
## 整体绕球心旋转 = 星球旋转 + 相对星球的自转；白昼天空固定在星空正上方，
## 镜头朝上，故相对角度即本节点 rotation。

@onready var night_sky: Sprite2D = $NightSky
@onready var _day_sky_material: ShaderMaterial = $DaySky.material

## 时段关键角（星空相对角度）：0=正午、π/2=夕阳、π=午夜、3π/2=朝霞、TAU 回到正午。
const DAY_PHASE_ANGLES: Array[float] = [0.0, PI * 0.5, PI, PI * 1.5, TAU]
## 各时段天顶色（首尾相同以保证环绕连续）。
const DAY_PHASE_ZENITH_COLORS: Array[Color] = [
	Color(0.36, 0.62, 0.88),
	Color(0.30, 0.22, 0.42),
	Color(0.01, 0.01, 0.04),
	Color(0.45, 0.55, 0.82),
	Color(0.36, 0.62, 0.88),
]
## 各时段地平线色（正午暖白、夕阳橙红、午夜深黑、朝霞粉橙）。
const DAY_PHASE_HORIZON_COLORS: Array[Color] = [
	Color(0.92, 0.86, 0.66),
	Color(1.0, 0.45, 0.2),
	Color(0.02, 0.03, 0.08),
	Color(1.0, 0.7, 0.66),
	Color(0.92, 0.86, 0.66),
]

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
## 夜图覆盖在白昼图之上，透明度随角度平滑过渡；白天天空同时按角度所处的
## 时段在关键色间插值，把红通道渐变替换为真实天空色。
func _update_daylight() -> void:
	var daylight := (cos(rotation) + 1.0) * 0.5
	night_sky.modulate.a = 1.0 - daylight
	var angle := fposmod(rotation, TAU)
	var index := 0
	while index < DAY_PHASE_ANGLES.size() - 2 and angle >= DAY_PHASE_ANGLES[index + 1]:
		index += 1
	var phase_blend := smoothstep(0.0, 1.0, remap(
		angle, DAY_PHASE_ANGLES[index], DAY_PHASE_ANGLES[index + 1], 0.0, 1.0
	))
	_day_sky_material.set_shader_parameter(
		"zenith_color", DAY_PHASE_ZENITH_COLORS[index].lerp(
			DAY_PHASE_ZENITH_COLORS[index + 1], phase_blend
		)
	)
	_day_sky_material.set_shader_parameter(
		"horizon_color", DAY_PHASE_HORIZON_COLORS[index].lerp(
			DAY_PHASE_HORIZON_COLORS[index + 1], phase_blend
		)
	)
