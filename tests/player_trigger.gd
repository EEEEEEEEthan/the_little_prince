extends SceneTree
## 325：走进国王 TriggerHello 时应自行进入并打开空气墙，且无 flushing queries。


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
	print("[player_trigger] 通过")
	shell.free()
	quit(0)
