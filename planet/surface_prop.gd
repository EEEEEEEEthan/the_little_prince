class_name SurfaceProp
extends Sprite2D
## 圆弧星球上的地表地物。玩法信号从子节点 PlayerTrigger 转到本节点，方便在编辑器里连线。

signal player_entered
signal player_exited
signal interacted

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
			trigger.is_armed = false


func _ready() -> void:
	var trigger := _player_trigger()
	if trigger == null:
		return
	trigger.player_entered.connect(player_entered.emit)
	trigger.player_exited.connect(player_exited.emit)
	trigger.interacted.connect(interacted.emit)


func arm_interact() -> void:
	_player_trigger().is_armed = true


func disarm_interact() -> void:
	_player_trigger().is_armed = false


func set_interact_kind(kind: WorldConstants.InteractKind) -> void:
	_player_trigger().interact_kind = kind


func play_ambient_one_shot() -> void:
	pass


func _player_trigger() -> Area2D:
	for child in get_children():
		if child.has_method("hosted_surface_prop"):
			return child
	return null
