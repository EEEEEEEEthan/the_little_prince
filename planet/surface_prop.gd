class_name SurfaceProp
extends Sprite2D
## 圆弧星球上的地表地物。玩法信号从子节点 PlayerTrigger 转到本节点，方便在编辑器里连线。

signal player_entered
signal player_exited
signal interacted

@export var is_armed: bool = false:
	set(value):
		is_armed = value
		if not is_node_ready():
			await ready
		var trigger := _player_trigger()
		if trigger == null:
			return
		trigger.is_armed = is_armed

@export var interact_kind: WorldConstants.InteractKind = WorldConstants.InteractKind.PRESS:
	set(value):
		interact_kind = value
		if not is_node_ready():
			await ready
		var trigger := _player_trigger()
		if trigger == null:
			return
		trigger.interact_kind = interact_kind

var is_consumed: bool = false:
	set(value):
		is_consumed = value
		if not is_node_ready():
			await ready
		var trigger := _player_trigger()
		if trigger == null:
			return
		trigger.monitorable = not is_consumed
		if is_consumed:
			is_armed = false


func _ready() -> void:
	var trigger := _player_trigger()
	if trigger == null:
		return
	trigger.player_entered.connect(player_entered.emit)
	trigger.player_exited.connect(player_exited.emit)
	trigger.interacted.connect(interacted.emit)


func play_ambient_one_shot() -> void:
	pass


func _player_trigger() -> Area2D:
	return get_node_or_null("PlayerTrigger") as Area2D
