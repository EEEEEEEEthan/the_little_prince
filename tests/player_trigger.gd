extends SceneTree
## PlayerTrigger 自己监测脚印；进入时改空气墙 enabled 不得报 flushing queries。


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	var footprint := Area2D.new()
	footprint.collision_layer = 1
	footprint.collision_mask = 0
	footprint.monitoring = false
	var footprint_shape := CollisionShape2D.new()
	var footprint_circle := CircleShape2D.new()
	footprint_circle.radius = WorldConstants.PLAYER_FOOTPRINT_RADIUS
	footprint_shape.shape = footprint_circle
	footprint.add_child(footprint_shape)
	var trigger: Area2D = (load("res://planet/player_trigger.tscn") as PackedScene).instantiate()
	var air_wall: Area2D = (load("res://planet/air_wall.tscn") as PackedScene).instantiate()
	air_wall.enabled = false
	trigger.player_entered.connect(air_wall.set_enabled.bind(true))
	holder.add_child(footprint)
	holder.add_child(trigger)
	holder.add_child(air_wall)
	var entered := false
	trigger.player_entered.connect(func() -> void:
		entered = true
	)
	for _frame in 8:
		await physics_frame
	if not entered or not trigger.player_is_inside:
		push_error("[player_trigger] 应自发检测脚印进入")
		quit(1)
		return
	if not air_wall.enabled:
		push_error("[player_trigger] 进入后应打开空气墙")
		quit(1)
		return
	trigger.position = Vector2(256.0, 0.0)
	for _frame in 8:
		await physics_frame
	if trigger.player_is_inside:
		push_error("[player_trigger] 离开后 player_is_inside 应为 false")
		quit(1)
		return
	print("[player_trigger] 通过")
	quit(0)
