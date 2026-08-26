extends SceneTree
## 交互时小王子应转向目标所在一侧。


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
	var player: Node2D = story.player
	planet.teleport_player(mouse.rotation + 0.2)
	await physics_frame
	await physics_frame
	planet.refresh_interact_focus()
	await process_frame
	var mouse_is_to_the_left: bool = mouse.global_position.x < player.global_position.x
	player.flip_h = not mouse_is_to_the_left
	if not story.accepts_interact(mouse):
		push_error("[interact_face_target] 应能与老鼠交互")
		quit(1)
		return
	if planet.focused_player_trigger == null:
		push_error("[interact_face_target] 应聚焦老鼠触发器")
		quit(1)
		return
	Input.action_press(&"interact")
	var press_event := InputEventAction.new()
	press_event.action = &"interact"
	press_event.pressed = true
	press_event.strength = 1.0
	Input.parse_input_event(press_event)
	await process_frame
	Input.action_release(&"interact")
	var release_event := InputEventAction.new()
	release_event.action = &"interact"
	release_event.pressed = false
	Input.parse_input_event(release_event)
	if player.flip_h != mouse_is_to_the_left:
		push_error("[interact_face_target] 交互后应面向老鼠")
		quit(1)
		return
	print("[interact_face_target] 通过")
	shell.free()
	quit(0)
