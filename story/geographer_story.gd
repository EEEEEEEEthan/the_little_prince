class_name GeographerStory
extends PlanetStory
## 330 号小行星：书房只记别人的报告；玫瑰太短不记，随后指向地球。


func _prepare_start() -> void:
	player.flip_h = true
	player.modulate.a = 1.0
	has_crossed_sunset = true
	set_process(false)


func _play_story() -> void:
	await _fade_in_from_black()
	await _overhead("这是一间书房。")
	player.can_move_left = true
	player.can_move_right = true
	is_blocking_input = false
	has_finished_opening = true
	var geographer := await _interact(SurfaceProp.Kind.GEOGRAPHER)
	await _geographer("我只记下别人的报告。")
	await _prince("我的玫瑰呢？")
	await _geographer("花存在得太短。我不记。")
	geographer.is_consumed = true
	await _camera_up()
	await _overhead("他指向地球。")
	await _depart("330。")


func _geographer(text: String) -> void:
	await _line(
			DialogueCatalog.GEOGRAPHER_SPEAKER,
			text,
			DialogueCatalog.GEOGRAPHER_PORTRAIT
	)
