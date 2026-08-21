extends Sprite2D
## 统一天空背景：单个 Sprite2D 绑定 sky.gdshader，TEXTURE 为星空贴图，
## 负责白天渐变色、夜空星图叠加与胶片颗粒效果。
## 整体绕球心旋转（星球旋转 + 自转），相位按星空相对角度实时更新 shader 参数。

## 星球旋转分量，由 Planet 同步写入。
var planet_rotation: float = 0.0
var star_rotation_speed: float = WorldConstants.STAR_ROTATION_SPEED
var is_self_rotating: bool = true
var _self_rotation: float = 0.0


func set_planet_rotation(value: float) -> void:
	planet_rotation = value
	rotation = planet_rotation + _self_rotation


func _process(delta: float) -> void:
	if is_self_rotating:
		_self_rotation = fposmod(
				_self_rotation - star_rotation_speed * delta, TAU
		)
	rotation = planet_rotation + _self_rotation
	_update_daylight()


func _update_daylight() -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
	var phase := SkyPhase.angle_to_phase(rotation)
	mat.set_shader_parameter("phase", phase)
