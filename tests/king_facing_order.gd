extends SceneTree
## 325：TriggerSleepy 之后转身面向/背向国王应触发对应命令。


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
	var sleepy: Area2D = planet.get_node("%TriggerSleepy")
	var walk_direction := signf(angle_difference(planet.player_angle, planet.king_angle))
	if is_zero_approx(walk_direction):
		walk_direction = 1.0
	var delta := 1.0 / 60.0
	for _step in 2400:
		planet.move_player(walk_direction, delta)
		await physics_frame
		if sleepy.player_is_inside:
			break
	if not sleepy.player_is_inside:
		push_error("[king_facing_order] 应走进 TriggerSleepy")
		quit(1)
		return
	while story.is_blocking_player_input() or not story.is_processing():
		await process_frame
	var player = story.player
	var was_facing_king: bool = story._player_is_facing_king()
	player.flip_h = not player.flip_h
	for _wait in 8:
		await process_frame
	var away_order := "我命令你走向远处！"
	var toward_order := "我命令你靠近我！"
	var expected_after_turn := toward_order if not was_facing_king else away_order
	if story.last_king_facing_order_text != expected_after_turn:
		push_error(
				"[king_facing_order] 转身后面向应变命令，得到：%s"
				% story.last_king_facing_order_text
		)
		quit(1)
		return
	while story.is_blocking_player_input():
		await process_frame
	player.flip_h = not player.flip_h
	for _wait_back in 8:
		await process_frame
	var expected_after_turn_back := away_order if not was_facing_king else toward_order
	if story.last_king_facing_order_text != expected_after_turn_back:
		push_error(
				"[king_facing_order] 再转身应说另一句，得到：%s"
				% story.last_king_facing_order_text
		)
		quit(1)
		return
	while story.is_blocking_player_input():
		await process_frame
	var order_range: Area2D = planet.get_node("%TriggerKingOrder")
	if not order_range.player_is_inside:
		push_error("[king_facing_order] 觐见后应已在 TriggerKingOrder 内")
		quit(1)
		return
	planet.teleport_player(fposmod(planet.king_angle + PI, TAU))
	await physics_frame
	await physics_frame
	if order_range.player_is_inside:
		push_error("[king_facing_order] 传送到背面后应离开 TriggerKingOrder")
		quit(1)
		return
	player.flip_h = not player.flip_h
	for _wait_outside in 8:
		await process_frame
	if story.last_king_facing_order_text != expected_after_turn_back:
		push_error(
				"[king_facing_order] 范围外转身不应下令，得到：%s"
				% story.last_king_facing_order_text
		)
		quit(1)
		return
	if not await _walk_into(planet, order_range, planet.king_angle):
		push_error("[king_facing_order] 应能从范围外走进 TriggerKingOrder")
		quit(1)
		return
	for _wait_enter in 8:
		await process_frame
	while story.is_blocking_player_input():
		await process_frame
	if story.last_king_facing_order_text != toward_order:
		push_error(
				"[king_facing_order] 进入范围应命令靠近，得到：%s"
				% story.last_king_facing_order_text
		)
		quit(1)
		return
	print("[king_facing_order] 通过")
	shell.free()
	quit(0)


func _walk_into(planet: Node2D, trigger: Area2D, target_angle: float) -> bool:
	var walk_direction := signf(angle_difference(planet.player_angle, target_angle))
	if is_zero_approx(walk_direction):
		walk_direction = 1.0
	var step_delta := 1.0 / 60.0
	for _step in 2400:
		planet.move_player(walk_direction, step_delta)
		await physics_frame
		if trigger.player_is_inside:
			await process_frame
			await process_frame
			return true
	return false

