class_name KingStory
extends PlanetStory
## 325 号小行星：背面降落，路上可点环境；觐见时对上现有国王对话（无日落）。

var has_overheard_distant_sentencing: bool = false


func _prepare_start() -> void:
	player.move_speed_scale = 0.65
	player.modulate.a = 1.0
	planet.has_contacted_audience_keep_away = false
	has_overheard_distant_sentencing = false
	set_process(false)


func _play_story() -> void:
	await _fade_in_from_black()
	await _overhead("下一颗星球上，住着一位国王。")
	player.can_move_left = true
	player.can_move_right = true
	is_blocking_input = false
	has_finished_opening = true
	_watch_rat_overhear()
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
	await _king("如果我命令一位将军变成海鸟，")
	await _king("而他不服从，那是我的错。")
	await _king("我的命令必须通情达理。")
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


func accepts_interact(prop: SurfaceProp) -> bool:
	if not is_active or is_blocking_input or prop.is_consumed:
		return false
	if _waiting_interact_kind >= 0:
		return int(prop.kind) == _waiting_interact_kind
	return prop.is_interactable() and prop.kind != SurfaceProp.Kind.KING


func try_handle_interact(prop: SurfaceProp) -> bool:
	if int(prop.kind) == _waiting_interact_kind:
		return super.try_handle_interact(prop)
	if not accepts_interact(prop):
		return false
	match prop.kind:
		SurfaceProp.Kind.EDICT:
			overhead.play_queued("诏上什么也没写。")
		SurfaceProp.Kind.THRONE:
			_glance_up_at_empty_throne()
		SurfaceProp.Kind.BORDER, SurfaceProp.Kind.CAPE, SurfaceProp.Kind.RAT_HOLE:
			prop.play_ambient_one_shot()
		_:
			return false
	return true


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


func _watch_rat_overhear() -> void:
	var generation := _story_generation
	var rat: SurfaceProp = null
	for prop in planet.surface_props:
		if prop.kind == SurfaceProp.Kind.RAT:
			rat = prop
			break
	var overhear_arc := WorldConstants.INTERACT_RANGE_PX * 2.0 / planet.radius
	while (
			is_inside_tree()
			and generation == _story_generation
			and not has_overheard_distant_sentencing
	):
		if (
				has_finished_opening
				and not is_blocking_input
				and absf(angle_difference(planet.player_angle, rat.rotation)) <= overhear_arc
		):
			has_overheard_distant_sentencing = true
			if not skip_cinematics:
				overhead.play_queued("「判你死刑。」")
				overhead.play_queued("「我赦免你。」")
			return
		await get_tree().process_frame


func _glance_up_at_empty_throne() -> void:
	if skip_cinematics:
		return
	var game_camera := %GameCamera
	var glance := game_camera.create_tween()
	glance.set_trans(Tween.TRANS_CUBIC)
	glance.set_ease(Tween.EASE_IN_OUT)
	glance.tween_property(game_camera, "offset:y", -16.0, 0.45)
	glance.tween_property(game_camera, "offset:y", 0.0, 0.55)
