class_name SurfaceProp
extends Sprite2D
## 圆弧星球上的地表地物（玫瑰 / 火山 / 猴面包树），脚底贴圆周、头朝外。
## 局部坐标以球心为原点，随 Surface 整体旋转到玩家视角。

enum Kind { ROSE, VOLCANO, BAOBAB }

const ROSE_TEXTURE: Texture2D = preload("res://planet/rose.png")
const VOLCANO_TEXTURE: Texture2D = preload("res://planet/volcano.png")
const BAOBAB_TEXTURE: Texture2D = preload("res://planet/baobab.png")

var kind: Kind
var angle: float

func configure(prop_kind: Kind, prop_angle: float) -> void:
	kind = prop_kind
	angle = prop_angle
	_apply_texture()
	_place_on_surface()

## 依据相对玩家角的可见性与前后深度，更新显示状态。
func update_visibility(player_angle: float) -> void:
	var relative_angle := angle_difference(player_angle, angle)
	visible = absf(relative_angle) <= WorldConstants.VISIBLE_HALF_ARC
	z_index = int(cos(relative_angle) * 100.0)

func _apply_texture() -> void:
	match kind:
		Kind.ROSE:
			texture = ROSE_TEXTURE
			name = "Rose"
		Kind.VOLCANO:
			texture = VOLCANO_TEXTURE
			name = "Volcano"
		Kind.BAOBAB:
			texture = BAOBAB_TEXTURE
			name = "Baobab"
	offset = Vector2(0.0, -float(texture.get_height()) * 0.5)

func _place_on_surface() -> void:
	position = Vector2(sin(angle), -cos(angle)) * WorldConstants.PLANET_RADIUS
	rotation = angle
