class_name KingStory
extends PlanetStory
## 325 号小行星：背面降落，路上只走场景；觐见时再对上现有国王对话。


func _prepare_start() -> void:
	player.move_speed_scale = 0.65
	player.modulate.a = 1.0
	planet.has_contacted_audience_keep_away = false
	set_process(false)


func _play_story() -> void:
	await _fade_in_from_black()
	await _overhead("下一颗星球上，住着一位国王。")
	player.can_move_left = true
	player.can_move_right = true
	is_blocking_input = false
	has_finished_opening = true
	await _await_distant_king_voice()
	await _await_audience_keep_away()
	await _king("过来。这是命令。")
	await _king("啊！来了一个臣民！")
	await _overhead("小王子打了个哈欠。")
	await _king("在国王面前打哈欠是违反礼节的。")
	await _king("我禁止你打哈欠。")
	await _prince("我忍不住。")
	await _prince("我走了很远，一直没睡觉。")
	await _king("那我命令你打哈欠。")
	await _king("好几年来我都没见人打哈欠了。")
	await _king("对我来说，打哈欠是新鲜事。")
	await _king("来！再打一个。这是命令。")
	await _prince("这叫我很为难...我打不出来了。")
	await _king("嗯！嗯！")
	await _overhead("国王有点难堪。")
	await _king("那么我命令你...")
	await _king("有时候打哈欠，有时候不打。")
	await _king("我是绝对的君主。")
	await _prince("陛下统治什么呢？")
	await _king("统治一切。")
	await _prince("一切？")
	await _king("一切。")
	await _overhead("他轻轻比了个手势，把所有星球都划进他的王国。")
	await _prince("那些星星都服从您吗？")
	await _king("当然。我不容许无纪律。")
	await _prince("请您命令太阳落山吧。")
	await _prince("我想看日落。")
	await _king("如果我命令一位将军变成海鸟，")
	await _king("而他不服从，那是我的错。")
	await _king("我的命令必须通情达理。")
	await _king("我会命令太阳落山。")
	await _king("但要等到条件成熟。")
	await _overhead("他说，傍晚就会下令。")
	_lock_input()
	await _camera_up()
	await _king("太阳！我命令你落山。")
	await _play_standing_sunset_sky()
	await _overhead("太阳正要落下。国王的命令被执行了。")
	await _wait(0.5)
	await _camera_down()
	player.move_speed_scale = 1.0
	is_blocking_input = false
	var king := await _interact(SurfaceProp.Kind.KING)
	await _king("我任命你为司法大臣。")
	await _prince("可是这儿没有人可以审判。")
	await _king("那可难说。")
	await _king("我很老了，这地方又小，我懒得走动。")
	await _king("我记得有一只老耗子。")
	await _king("夜里我听见它。")
	await _king("你可以审判它。")
	await _prince("我不想判任何人死刑。")
	await _king("你可以赦免它。")
	await _king("我可以下令让你赦免它。")
	await _prince("我要走了。")
	await _king("不许。")
	await _overhead("小王子犹豫了一下。")
	await _king("我任命你为我的大使。")
	await _prince("再见。")
	await _overhead("国王的权威得到了尊重。")
	await _overhead("因为他的命令都是通情达理的。")
	king.is_consumed = true
	await _depart("325。")


func _king(text: String) -> void:
	await _line(DialogueCatalog.KING_SPEAKER, text, DialogueCatalog.KING_PORTRAIT)


func _await_distant_king_voice() -> void:
	var generation := _story_generation
	if skip_cinematics:
		await _halt_if_stale(generation)
		return
	while (
			is_inside_tree()
			and generation == _story_generation
			and not planet.is_in_distant_king_voice_range()
	):
		await get_tree().process_frame
	await _overhead("「……听着。」")
	await _halt_if_stale(generation)


func _await_audience_keep_away() -> void:
	var generation := _story_generation
	while (
			is_inside_tree()
			and generation == _story_generation
			and not planet.has_contacted_audience_keep_away
	):
		await get_tree().process_frame
	await _halt_if_stale(generation)


func _play_standing_sunset_sky() -> void:
	var generation := _story_generation
	var sky := planet.sky
	if skip_cinematics:
		sky.commanded_daylight_phase = SkyPhase.SUNSET_PHASE
		await _halt_if_stale(generation)
		return
	sky.commanded_daylight_phase = sky.daylight_phase()
	if _story_tween != null:
		_story_tween.kill()
	_story_tween = create_tween()
	_story_tween.tween_property(
			sky, "commanded_daylight_phase", SkyPhase.SUNSET_PHASE, 2.4
	)
	await _story_tween.finished
	_story_tween = null
	await _halt_if_stale(generation)
