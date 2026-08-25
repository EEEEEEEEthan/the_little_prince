class_name SurfaceProp
extends Sprite2D
## 圆弧星球上的地表地物，拖到 Planet 的 Surface 下即可。
## 位置、贴图、帧、层级均在 tscn 中定死；运行期仅按玩家角更新可见性。
## 交互只发事件；对白、头顶字等响应由业务监听。

signal interacted

@export var variant: int = 0
@export var interaction_enabled: bool = false
var is_consumed: bool = false:
	set(value):
		is_consumed = value
		if not is_node_ready():
			await ready
		for child in get_children():
			if child.has_method("hosted_surface_prop"):
				child.monitorable = not is_consumed
		if is_consumed:
			visible = false


func is_interactable() -> bool:
	return interaction_enabled and not is_consumed


func interact() -> void:
	interacted.emit()


## 依据相对玩家角的可见性更新显示状态。
func update_visibility(player_angle: float) -> void:
	if is_consumed:
		visible = false
		return
	var relative_angle := angle_difference(player_angle, rotation)
	visible = absf(relative_angle) <= WorldConstants.VISIBLE_HALF_ARC
