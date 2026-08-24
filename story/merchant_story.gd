class_name MerchantStory
extends "res://story/planet_story.gd"
## 328 号小行星：地是账本，星星在天上；商人从不抬头，玻璃罐一点即过。


func _prepare_start() -> void:
	player.flip_h = true
	player.modulate.a = 1.0
	has_crossed_sunset = true
	planet.sky.commanded_daylight_phase = 0.0


func _process(_delta: float) -> void:
	super._process(_delta)
	if not has_finished_opening or is_blocking_input:
		return
	var look_up_amount := Input.get_action_strength(&"move_up")
	%GameCamera.offset.y = lerpf(
			%GameCamera.offset.y,
			-16.0 * look_up_amount,
			0.2
	)


func _play_story() -> void:
	await _fade_in_from_black()
	await _camera_up()
	await _overhead("星星都在天上。")
	await _camera_down()
	player.can_move_left = true
	player.can_move_right = true
	is_blocking_input = false
	has_finished_opening = true
	var star_jar := await _interact(SurfaceProp.Kind.STAR_JAR)
	await _overhead("他把它们锁进玻璃罐，自己从不抬头。")
	star_jar.is_consumed = true
	await _depart("328。")
