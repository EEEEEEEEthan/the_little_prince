class_name SurfaceProp
extends Sprite2D
## 圆弧星球上的地表地物（玫瑰 / 火山 / 猴面包树 / 地表植物），拖到 Planet 的 Surface 下即可。
## 位置、贴图、帧、层级均在 tscn 中定死；运行期仅按玩家角更新可见性。

enum Kind { ROSE, VOLCANO, BAOBAB, FLORA }

@export var kind: Kind = Kind.ROSE
@export var variant: int = 0
## 对话目录 id；空则按 kind 回落。火山与地表植物无对话。
@export var dialogue_id: StringName = &""
var is_consumed: bool = false


func get_dialogue_id() -> StringName:
	if dialogue_id != &"":
		return dialogue_id
	match kind:
		Kind.ROSE:
			return &"rose"
		Kind.BAOBAB:
			return &"baobab"
	return &""


func is_interactable() -> bool:
	match kind:
		Kind.VOLCANO, Kind.FLORA:
			return false
	return not is_consumed and get_dialogue_id() != &""


## 依据相对玩家角的可见性更新显示状态。
func update_visibility(player_angle: float) -> void:
	if is_consumed and kind == Kind.BAOBAB:
		visible = false
		return
	var relative_angle := angle_difference(player_angle, rotation)
	visible = absf(relative_angle) <= WorldConstants.VISIBLE_HALF_ARC
