extends SceneTree
## 无头：确认 Flora 触发器带 is_grass，踩在草丛角时 Player.is_in_grass。


func _init() -> void:
	call_deferred(&"_begin")


func _begin() -> void:
	var flora: Node = (load("res://planet/flora.tscn") as PackedScene).instantiate()
	root.add_child(flora)
	var trigger: Area2D = flora.get_node("PlayerTrigger")
	if not trigger.is_grass:
		push_error("[grass_overlap] Flora PlayerTrigger.is_grass 应为 true")
		quit(1)
		return
	if not trigger.is_in_group(&"grass"):
		push_error("[grass_overlap] is_grass 应变为 grass 组")
		quit(1)
		return
	flora.queue_free()
	var packed_scene := load("res://planet/main.tscn") as PackedScene
	var shell: Node = packed_scene.instantiate()
	shell.get_node("Journey").travel_to_next_planet = false
	root.add_child(shell)
	var planet: Node = shell.get_node("%Planet")
	var player: Node = shell.get_node("%Player")
	if planet.flora_angles.is_empty():
		push_error("[grass_overlap] B612 没有 Flora")
		quit(1)
		return
	planet.teleport_player(planet.flora_angles[0])
	await process_frame
	await physics_frame
	await physics_frame
	if not player.is_in_grass():
		push_error("[grass_overlap] 传送到草丛后 is_in_grass 应为 true")
		quit(1)
		return
	print("[grass_overlap] 通过")
	quit(0)
