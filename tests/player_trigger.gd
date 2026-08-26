extends SceneTree
## 325：TriggerHello 打开空气墙；TriggerSleepy 后空气墙关闭。且无 flushing queries。


func _init() -> void:
	call_deferred(&"_begin")


func _begin() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	if not await _prompt_follows_world_up():
		return
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
	var hello: Area2D = planet.get_node("%TriggerHello")
	var air_wall: Area2D = planet.get_node("Surface/King/AirWall")
	var walk_direction := signf(angle_difference(planet.player_angle, planet.king_angle))
	if is_zero_approx(walk_direction):
		walk_direction = 1.0
	var delta := 1.0 / 60.0
	for _step in 1800:
		planet.move_player(walk_direction, delta)
		await physics_frame
		if hello.player_is_inside:
			await process_frame
			await process_frame
			break
	if not hello.player_is_inside:
		push_error("[player_trigger] 走近国王后 TriggerHello 应自行判定进入")
		quit(1)
		return
	if not air_wall.enabled:
		push_error("[player_trigger] 进入 TriggerHello 后空气墙应打开")
		quit(1)
		return
	var sleepy: Area2D = planet.get_node("%TriggerSleepy")
	for _sleepy_step in 1800:
		planet.move_player(walk_direction, delta)
		await physics_frame
		if sleepy.player_is_inside:
			await process_frame
			await process_frame
			break
	if not sleepy.player_is_inside:
		push_error("[player_trigger] 走近国王后 TriggerSleepy 应自行判定进入")
		quit(1)
		return
	if air_wall.enabled:
		push_error("[player_trigger] 进入 TriggerSleepy 后空气墙应关闭")
		quit(1)
		return
	print("[player_trigger] 通过")
	shell.free()
	quit(0)


func _prompt_follows_world_up() -> bool:
	var trigger: Area2D = (load("res://planet/player_trigger.tscn") as PackedScene).instantiate()
	root.add_child(trigger)
	trigger.global_position = Vector2(80.0, 120.0)
	trigger.rotation = TAU * 0.25
	trigger.is_focused = true
	await process_frame
	var prompt: Sprite2D
	for child in trigger.get_children():
		if child is Sprite2D:
			prompt = child
			break
	var expected_global_position := trigger.global_position + Vector2(0.0, WorldConstants.INTERACT_PROMPT_WORLD_Y)
	var local_up_global_position := trigger.to_global(Vector2(0.0, WorldConstants.INTERACT_PROMPT_WORLD_Y))
	var passed := true
	if prompt == null:
		push_error("[player_trigger] 聚焦后应生成提示")
		passed = false
	elif not prompt.global_position.is_equal_approx(expected_global_position):
		push_error("[player_trigger] 提示应在 trigger 世界坐标向上，实际 %s 期望 %s" % [prompt.global_position, expected_global_position])
		passed = false
	elif prompt.global_position.is_equal_approx(local_up_global_position):
		push_error("[player_trigger] 旋转后世界向上与本地向上应不同")
		passed = false
	trigger.free()
	if not passed:
		quit(1)
	return passed
