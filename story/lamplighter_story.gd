class_name LamplighterStory
extends "res://story/planet_story.gd"
## 329 号小行星：最小、昼夜极快；陪几轮、帮点一次，站不下只能走。

const ACCOMPANY_DAY_NIGHT_ROUND_COUNT := 3


func _prepare_start() -> void:
	player.flip_h = true
	player.modulate.a = 1.0
	has_crossed_sunset = true


func _play_story() -> void:
	await _fade_in_from_black()
	player.can_move_left = true
	player.can_move_right = true
	is_blocking_input = false
	has_finished_opening = true
	var generation := _story_generation
	if not skip_cinematics:
		var completed_round_count := 0
		var was_night := SkyPhase.is_night_phase(planet.sky.daylight_phase())
		while (
				completed_round_count < ACCOMPANY_DAY_NIGHT_ROUND_COUNT
				and is_inside_tree()
		):
			await get_tree().process_frame
			await _halt_if_stale(generation)
			var is_night := SkyPhase.is_night_phase(planet.sky.daylight_phase())
			if is_night and not was_night:
				completed_round_count += 1
			was_night = is_night
	var street_lamp := await _interact(SurfaceProp.Kind.STREET_LAMP)
	await _overhead("他让我帮着点了一次。")
	street_lamp.is_consumed = true
	await _overhead("这颗太小了，两个人站不下。")
	await _depart("329。")
