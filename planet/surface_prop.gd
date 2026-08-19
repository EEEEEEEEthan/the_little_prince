class_name SurfaceProp
extends Sprite2D
## 圆弧星球上的地表地物（玫瑰 / 火山 / 猴面包树），静态写在星球场景内，
## 位置、贴图、帧均在 tscn 中定死；运行期仅按玩家角更新可见性与前后深度。

enum Kind { ROSE, VOLCANO, BAOBAB }

@export var kind: Kind = Kind.ROSE
@export var variant: int = 0
## 对话目录 id；空则按 kind 回落（活火山 / 死火山分开）。
@export var dialogue_id: StringName = &""

func get_dialogue_id() -> StringName:
	if dialogue_id != &"":
		return dialogue_id
	match kind:
		Kind.ROSE:
			return &"rose"
		Kind.VOLCANO:
			if variant == WorldConstants.VOLCANO_ACTIVE_VARIANT:
				return &"volcano_active"
			return &"volcano_dead"
		Kind.BAOBAB:
			return &"baobab"
	return &""

func is_interactable() -> bool:
	return get_dialogue_id() != &""

## 依据相对玩家角的可见性与前后深度更新显示状态。
func update_visibility(player_angle: float) -> void:
	var relative_angle := angle_difference(player_angle, rotation)
	visible = absf(relative_angle) <= WorldConstants.VISIBLE_HALF_ARC
	z_index = int(cos(relative_angle) * 100.0)
