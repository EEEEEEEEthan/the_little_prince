extends SceneTree
## 空气墙：visible 时不能走进区域；已在内部可离开；隐藏后可穿过。


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var planet: Node2D = (load("res://planet/planet.tscn") as PackedScene).instantiate()
	root.add_child(planet)
	var air_wall: Area2D = (load("res://planet/air_wall.tscn") as PackedScene).instantiate()
	var wall_angle := 0.35
	air_wall.position = Vector2(sin(wall_angle), -cos(wall_angle)) * planet.radius
	air_wall.rotation = wall_angle
	planet.surface.add_child(air_wall)
	planet.teleport_player(0.0)
	var delta := 1.0 / 60.0
	for _step in 240:
		planet.move_player(1.0, delta)
	if planet.player_angle > wall_angle:
		push_error("[air_wall] visible 时不应穿过空气墙")
		quit(1)
		return
	if is_zero_approx(planet.player_angle):
		push_error("[air_wall] 应从外侧贴住空气墙")
		quit(1)
		return
	planet.teleport_player(wall_angle)
	var angle_inside := planet.player_angle
	planet.move_player(-1.0, delta * 8.0)
	if is_equal_approx(planet.player_angle, angle_inside):
		push_error("[air_wall] 已在墙内时应能离开")
		quit(1)
		return
	planet.teleport_player(0.0)
	air_wall.visible = false
	for _step in 240:
		planet.move_player(1.0, delta)
	if planet.player_angle <= wall_angle:
		push_error("[air_wall] 隐藏后应能穿过空气墙")
		quit(1)
		return
	print("[air_wall] 通过")
	quit(0)
