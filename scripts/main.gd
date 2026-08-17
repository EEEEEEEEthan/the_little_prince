extends Control
## 全局总控：外层 Control 铺满窗口；内部 256×224 SubViewport 像素渲染后最近邻放大。
##
##   Main (Control)
##   └── GameView (SubViewportContainer, stretch + Nearest)
##       └── GameViewport (SubViewport 256×224)
##           ├── Starfield
##           ├── Planet —— Body + Surface 同受 -player_angle
##           └── Player —— 改角后立刻通知 Planet；始终钉在弧顶
##
## 世界布局基于固定内部分辨率，外层只做像素放大，不再按窗口缩放世界。

@onready var game_view: SubViewportContainer = $GameView
@onready var game_viewport: SubViewport = $GameView/GameViewport
@onready var starfield: Starfield = $GameView/GameViewport/Starfield
@onready var planet: Planet = $GameView/GameViewport/Planet
@onready var player: Player = $GameView/GameViewport/Player

func _ready() -> void:
	InputSetup.ensure_move_actions()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_configure_pixel_viewport()
	player.planet = planet
	_layout_world()
	# 出生角靠近玫瑰；set_angle_and_sync 同帧驱动 Body/Surface
	player.set_angle_and_sync(planet.spawn_angle)

func _configure_pixel_viewport() -> void:
	game_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_view.stretch = true
	game_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	game_viewport.size = Vector2i(WorldConstants.INTERNAL_WIDTH, WorldConstants.INTERNAL_HEIGHT)
	game_viewport.transparent_bg = false
	game_viewport.handle_input_locally = true
	game_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

## 固定 256×224：小半径 + 高 APEX_Y_RATIO → 球心更靠下，底部只露浅弧
func _layout_world() -> void:
	var size := Vector2(
		float(WorldConstants.INTERNAL_WIDTH),
		float(WorldConstants.INTERNAL_HEIGHT)
	)
	var radius: float = WorldConstants.PLANET_RADIUS
	var apex_y: float = size.y * WorldConstants.APEX_Y_RATIO
	# 弧顶在 apex_y，球心在其正下方 radius 处（通常已落在视口底边之外）
	var center := Vector2(size.x * 0.5, apex_y + radius)

	planet.apply_layout(center, radius)
	player.set_planet_radius(radius)
	player.place_at_apex(planet.apex_global_position())
