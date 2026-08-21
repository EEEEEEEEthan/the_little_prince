class_name SurfaceProp
extends Sprite2D
## 圆弧星球上的地表地物，拖到 Planet 的 Surface 下即可。
## 位置、贴图、帧、层级均在 tscn 中定死；运行期仅按玩家角更新可见性。

enum Kind { ROSE, VOLCANO, BAOBAB, FLORA, KING, RAT, EDICT, BORDER, RAT_TRACE, THRONE, CAPE }

@export var kind: Kind = Kind.ROSE
@export var variant: int = 0
## 对话目录 id；空则按 kind 回落。装饰性地物无对话。
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
		Kind.KING:
			return &"king"
	return &""


func is_interactable() -> bool:
	match kind:
		Kind.VOLCANO, Kind.FLORA, Kind.RAT, Kind.EDICT, Kind.BORDER, Kind.RAT_TRACE, Kind.THRONE, Kind.CAPE:
			return false
	return not is_consumed and get_dialogue_id() != &""


## 依据相对玩家角的可见性更新显示状态。
func update_visibility(player_angle: float) -> void:
	if is_consumed and kind == Kind.BAOBAB:
		visible = false
		return
	var relative_angle := angle_difference(player_angle, rotation)
	var is_on_facing_hemisphere := absf(relative_angle) <= WorldConstants.VISIBLE_HALF_ARC
	visible = is_on_facing_hemisphere
	if kind != Kind.KING:
		return
	if is_on_facing_hemisphere:
		return
	var signed_from_king := angle_difference(rotation, player_angle)
	flip_h = signed_from_king < 0.0
