class_name Butterfly
extends AnimatedSprite2D
## 草地上空飞舞：绕家园小范围盘旋，转到背面则隐藏。

var _home_orbital_angle: float = 0.0
var _home_orbit_radius: float = 0.0
var _elapsed_seconds: float = 0.0


func _ready() -> void:
	_home_orbital_angle = atan2(position.x, -position.y)
	_home_orbit_radius = position.length()
	_elapsed_seconds = _home_orbital_angle * 13.0
	speed_scale = 0.8 + fposmod(_home_orbital_angle, 1.0) * 0.5
	frame_progress = fposmod(_home_orbital_angle * 3.0, 1.0)
	play()


func _process(delta: float) -> void:
	_elapsed_seconds += delta
	const slow_wander_speed := 0.55
	const slow_wander_arc := 0.11
	const fast_wander_speed := 1.17
	const fast_wander_arc := 0.07
	var wander_arc := (
			sin(_elapsed_seconds * slow_wander_speed) * slow_wander_arc
			+ sin(_elapsed_seconds * fast_wander_speed) * fast_wander_arc
	)
	var orbital_angle := _home_orbital_angle + wander_arc
	var orbit_radius := (
			_home_orbit_radius
			+ sin(_elapsed_seconds * 1.4 + 0.6) * 3.0
	)
	position = Vector2(sin(orbital_angle), -cos(orbital_angle)) * orbit_radius
	rotation = orbital_angle
	var wander_rate := (
			cos(_elapsed_seconds * slow_wander_speed) * slow_wander_speed * slow_wander_arc
			+ cos(_elapsed_seconds * fast_wander_speed) * fast_wander_speed * fast_wander_arc
	)
	flip_h = wander_rate < 0.0
	var relative_angle := global_rotation
	visible = absf(relative_angle) <= WorldConstants.VISIBLE_HALF_ARC
	z_index = int(cos(relative_angle) * 100.0) + 12
