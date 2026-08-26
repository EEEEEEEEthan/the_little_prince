extends SceneTree
## 无头：325 小老鼠三次交互后跑掉；国王下令后同一只老鼠回来，宣判与赦免循环。


func _init() -> void:
	call_deferred(&"_begin")


func _begin() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var shell: Node = (load("res://planet/planet_run_shell.tscn") as PackedScene).instantiate()
	var planet: Node2D = (load("res://planet/325.tscn") as PackedScene).instantiate()
	planet.name = "Planet"
	planet.unique_name_in_owner = true
	var story := planet.get_node("%Story") as PlanetStory
	story.skip_cinematics = true
	shell.get_node("GameView/GameViewport").add_child(planet)
	planet.owner = shell
	root.add_child(shell)
	while not story.has_finished_opening or story.is_blocking_input:
		await process_frame
	var mouse: SurfaceProp = planet.get_node("%Mouse")
	var mouse_instance_id := mouse.get_instance_id()
	var mouse_faces_player := func() -> bool:
		var player_is_to_the_left: bool = mouse.global_position.x > planet.apex_global_position().x
		if mouse.flip_h != player_is_to_the_left:
			push_error("老鼠应朝向玩家所在一侧")
			return false
		return true
	planet.teleport_player(mouse.rotation)
	await process_frame
	await process_frame
	if not mouse_faces_player.call():
		quit(1)
		return
	planet.teleport_player(fposmod(mouse.rotation + 0.6, TAU))
	await process_frame
	await process_frame
	if not mouse_faces_player.call():
		quit(1)
		return
	planet.teleport_player(mouse.rotation)
	await process_frame
	await process_frame
	if not story.accepts_interact(mouse):
		push_error("出生后应能点小老鼠")
		quit(1)
		return
	if mouse.interacted.get_connections().is_empty():
		push_error("老鼠 interacted 未接到剧情")
		quit(1)
		return
	for squeak_index in 3:
		mouse.interacted.emit()
		while story.is_blocking_input:
			await process_frame
	await create_timer(0.7).timeout
	if not mouse.is_consumed or mouse.visible:
		push_error("第三次后小老鼠应跑掉")
		quit(1)
		return
	if not await _walk_into(planet, planet.get_node("%TriggerHello"), planet.king_angle):
		push_error("应能走到国王 TriggerHello")
		quit(1)
		return
	while story.is_blocking_input:
		await process_frame
	if not await _walk_into(planet, planet.get_node("%TriggerSleepy"), planet.king_angle):
		push_error("应能走到 TriggerSleepy")
		quit(1)
		return
	var sleepy: Area2D = planet.get_node("%TriggerSleepy")
	for king_talk_index in 4:
		while story.is_blocking_input or not sleepy.is_armed:
			await process_frame
		sleepy.interacted.emit()
		while story.is_blocking_input:
			await process_frame
	if mouse.get_instance_id() != mouse_instance_id:
		push_error("审判时应仍是同一只老鼠")
		quit(1)
		return
	if mouse.is_consumed or not mouse.visible:
		push_error("国王下令审判后小老鼠应回来")
		quit(1)
		return
	story.skip_cinematics = false
	planet.teleport_player(mouse.rotation)
	await process_frame
	await process_frame
	if not story.accepts_interact(mouse):
		push_error("审判阶段应能点小老鼠")
		quit(1)
		return
	var expected_verdicts: PackedStringArray = [
		"我，B612星王子，325星大臣，代表325国王，宣判你死刑",
		"我，B612星王子，325星大臣，代表325国王，赦免你的死罪",
		"我，B612星王子，325星大臣，代表325国王，宣判你死刑",
	]
	for expected_verdict in expected_verdicts:
		mouse.interacted.emit()
		if not await _await_open_line(story, expected_verdict):
			quit(1)
			return
		story.dialogue.close()
		while story.is_blocking_input:
			await process_frame
	if mouse.is_consumed or not mouse.visible:
		push_error("审判循环不应让老鼠再消失")
		quit(1)
		return
	print("[mouse_joke] 通过")
	shell.free()
	quit(0)


func _walk_into(planet: Node2D, trigger: Area2D, target_angle: float) -> bool:
	var walk_direction := signf(angle_difference(planet.player_angle, target_angle))
	if is_zero_approx(walk_direction):
		walk_direction = 1.0
	var step_delta := 1.0 / 60.0
	for _step in 1800:
		planet.move_player(walk_direction, step_delta)
		await physics_frame
		if trigger.player_is_inside:
			await process_frame
			await process_frame
			return true
	return false


func _await_open_line(story: PlanetStory, expected_text: String) -> bool:
	for _frame in 120:
		if story.dialogue.is_open():
			var spoken_text: String = story.dialogue.get_node("%Body").text
			if spoken_text != expected_text:
				push_error("对白不符：%s" % spoken_text)
				return false
			return true
		await process_frame
	push_error("未等到对白：%s" % expected_text)
	return false
