class_name SurfaceProp
extends Sprite2D
## 圆弧星球上的地表地物（玫瑰 / 火山 / 猴面包树），静态写在星球场景内，
## 位置、贴图、帧均在 tscn 中定死；运行期仅按玩家角更新可见性与前后深度。

enum Kind { ROSE, VOLCANO, BAOBAB }

@export var kind: Kind = Kind.ROSE
@export var variant: int = 0

## 依据相对玩家角的可见性与前后深度更新显示状态。
func update_visibility(player_angle: float) -> void:
	var relative_angle := angle_difference(player_angle, rotation)
	visible = absf(relative_angle) <= WorldConstants.VISIBLE_HALF_ARC
	z_index = int(cos(relative_angle) * 100.0)
