extends SceneTree
## 无头：325 小老鼠四次交互后跑掉。


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
	for squeak_index in 4:
		mouse.interacted.emit()
		while story.is_blocking_input:
			await process_frame
	await create_timer(0.7).timeout
	if not mouse.is_consumed or mouse.visible:
		push_error("第四次后小老鼠应跑掉")
		quit(1)
		return
	print("[mouse_joke] 通过")
	shell.free()
	quit(0)
