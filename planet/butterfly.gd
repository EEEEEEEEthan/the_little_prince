class_name Butterfly
extends AnimatedSprite2D
## 草地上空飞舞：绕家园小范围盘旋，转到背面则隐藏。
## 若设置了引导目标，开场先停住，调用 begin_guide_flight 后淡入再沿地表飞向目标。

@export var guide_target_local_position: Vector2 = Vector2.ZERO

var _home_orbital_angle: float = 0.0
var _home_orbit_radius: float = 0.0
var _elapsed_seconds: float = 0.0
var _guide_flight_progress: float = 0.0


func _ready() -> void:
	_home_orbital_angle = atan2(position.x, -position.y)
	_home_orbit_radius = position.length()
	if guide_target_local_position == Vector2.ZERO:
		_elapsed_seconds = _home_orbital_angle * 13.0
	speed_scale = 0.8 + fposmod(_home_orbital_angle, 1.0) * 0.5
	frame_progress = fposmod(_home_orbital_angle * 3.0, 1.0)
	play()


func begin_guide_flight() -> void:
	if not is_zero_approx(modulate.a):
		return
	_elapsed_seconds = 0.0
	create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).tween_property(
			self,
			"modulate:a",
			1.0,
			1.2,
	)


func _process(delta: float) -> void:
	var has_guide_target := guide_target_local_position != Vector2.ZERO
	var is_waiting_to_begin_guide := has_guide_target and is_zero_approx(modulate.a)
	if not is_waiting_to_begin_guide:
		_elapsed_seconds += delta
		var altitude_bob := sin(_elapsed_seconds * 1.4 + 0.6) * 3.0
		var orbital_angle := _home_orbital_angle
		var orbit_radius := _home_orbit_radius + altitude_bob
		if has_guide_target:
			var target_orbital_angle := atan2(
					guide_target_local_position.x,
					-guide_target_local_position.y,
			)
			var target_orbit_radius := guide_target_local_position.length()
			if modulate.a >= 1.0:
				var orbital_span := absf(angle_difference(
						_home_orbital_angle,
						target_orbital_angle,
				))
				_guide_flight_progress = minf(
						1.0,
						_guide_flight_progress
						+ delta * WorldConstants.PLAYER_SPEED
						/ (orbital_span * WorldConstants.PLANET_RADIUS),
				)
			orbital_angle = lerp_angle(
					_home_orbital_angle,
					target_orbital_angle,
					_guide_flight_progress,
			)
			orbit_radius = (
					lerpf(_home_orbit_radius, target_orbit_radius, _guide_flight_progress)
					+ altitude_bob
			)
			flip_h = false
		else:
			const slow_wander_speed := 0.55
			const slow_wander_arc := 0.11
			const fast_wander_speed := 1.17
			const fast_wander_arc := 0.07
			var wander_arc := (
					sin(_elapsed_seconds * slow_wander_speed) * slow_wander_arc
					+ sin(_elapsed_seconds * fast_wander_speed) * fast_wander_arc
			)
			orbital_angle = _home_orbital_angle + wander_arc
			var wander_rate := (
					cos(_elapsed_seconds * slow_wander_speed)
					* slow_wander_speed
					* slow_wander_arc
					+ cos(_elapsed_seconds * fast_wander_speed)
					* fast_wander_speed
					* fast_wander_arc
			)
			flip_h = wander_rate < 0.0
		position = Vector2(sin(orbital_angle), -cos(orbital_angle)) * orbit_radius
		rotation = orbital_angle
	var relative_angle := global_rotation
	visible = absf(relative_angle) <= WorldConstants.VISIBLE_HALF_ARC
	z_index = int(cos(relative_angle) * 100.0) + 12
