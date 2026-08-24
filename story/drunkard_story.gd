class_name DrunkardStory
extends "res://story/planet_story.gd"
## 327 号小行星：瓶子围成走不脱的圈，只有一句台词。


func _prepare_start() -> void:
	player.flip_h = true
	player.modulate.a = 1.0
	planet.sky.is_self_rotating = false
	planet.sky.commanded_daylight_phase = SkyPhase.SUNSET_PHASE
	set_process(false)


func _play_story() -> void:
	await _fade_in_from_black()
	player.can_move_left = true
	player.can_move_right = true
	is_blocking_input = false
	has_finished_opening = true
	var drunkard := await _interact(SurfaceProp.Kind.DRUNKARD)
	await _line(
			DialogueCatalog.DRUNKARD_SPEAKER,
			"喝是为了忘羞耻",
			DialogueCatalog.DRUNKARD_PORTRAIT
	)
	drunkard.is_consumed = true
	await _depart("327。")
