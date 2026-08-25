class_name SurfaceProp
extends Sprite2D
## 圆弧星球上的地表地物。基类场景带 %PlayerTrigger，玩法信号转到本节点。

signal player_entered
signal player_exited
signal interacted

@export var is_armed: bool = false:
	set(value):
		is_armed = value
		if not is_node_ready():
			await ready
		%PlayerTrigger.is_armed = is_armed

@export var interact_kind: WorldConstants.InteractKind = WorldConstants.InteractKind.PRESS:
	set(value):
		interact_kind = value
		if not is_node_ready():
			await ready
		%PlayerTrigger.interact_kind = interact_kind

var is_consumed: bool = false:
	set(value):
		is_consumed = value
		if not is_node_ready():
			await ready
		%PlayerTrigger.monitoring = not is_consumed
		if is_consumed:
			is_armed = false


func _ready() -> void:
	%PlayerTrigger.player_entered.connect(player_entered.emit)
	%PlayerTrigger.player_exited.connect(player_exited.emit)
	%PlayerTrigger.interacted.connect(interacted.emit)


func play_ambient_one_shot() -> void:
	pass
