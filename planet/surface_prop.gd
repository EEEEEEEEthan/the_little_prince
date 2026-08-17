class_name SurfaceProp
extends Sprite2D
## 圆弧星球上的地表地物（玫瑰 / 火山 / 猴面包树），脚底贴圆周、头朝外。
## 局部坐标以球心为原点，随 Surface 整体旋转到玩家视角。

enum Kind { ROSE, VOLCANO, BAOBAB }

const ROSE_TEXTURE: Texture2D = preload("res://planet/rose.png")
const VOLCANO_SHEET: Texture2D = preload("res://planet/volcano.png")
const BAOBAB_SHEET: Texture2D = preload("res://planet/baobab.png")

var kind: Kind
var angle: float
var variant: int

func configure(prop_kind: Kind, prop_angle: float, prop_variant: int = 0) -> void:
	kind = prop_kind
	angle = prop_angle
	variant = prop_variant
	_apply_texture()
	_place_on_surface()

## 依据相对玩家角的可见性与前后深度，更新显示状态。
func update_visibility(player_angle: float) -> void:
	var relative_angle := angle_difference(player_angle, angle)
	visible = absf(relative_angle) <= WorldConstants.VISIBLE_HALF_ARC
	z_index = int(cos(relative_angle) * 100.0)

func _apply_texture() -> void:
	# 贴图底部到脚底之间的透明留白比例，据此让脚底贴住圆周。
	var base_fraction := 1.0
	match kind:
		Kind.ROSE:
			texture = ROSE_TEXTURE
			name = "Rose"
			base_fraction = 0.96
		Kind.VOLCANO:
			texture = VOLCANO_SHEET
			hframes = WorldConstants.VOLCANO_VARIANT_COUNT
			frame = variant
			name = "Volcano"
			base_fraction = 0.90 if variant == 1 else 0.86
		Kind.BAOBAB:
			texture = BAOBAB_SHEET
			hframes = WorldConstants.BAOBAB_VARIANT_COUNT
			frame = variant
			name = "Baobab"
			base_fraction = 0.92
	var frame_height := float(texture.get_height())
	offset = Vector2(0.0, frame_height * (0.5 - base_fraction))

func _place_on_surface() -> void:
	position = Vector2(sin(angle), -cos(angle)) * WorldConstants.PLANET_RADIUS
	rotation = angle
