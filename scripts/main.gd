extends Control
## 全局总控：
##  1) 确保 InputMap 已注册 WASD/方向键（不依赖 project.godot 解析是否成功）；
##  2) 等待隐藏的 SubViewport 把地图 + 小王子渲染完成（地物不进球面贴图）；
##  3) 把该渲染结果（ViewportTexture）交给 PlanetView 的球面 Shader；
##  4) 每帧写入玩家 UV 与 PlanetView 尺寸，保证球心跟随且剪影为正圆；
##  5) PropScreenOverlay 用同一套逆投影把地物叠在 PlanetView 之上，边缘可凸出圆外。
##
## 场景树：
##   Main (Control，全屏)
##   ├── WorldHost (Node，仅承载隐藏渲染用的 SubViewport)
##   │   └── WorldViewport (SubViewport，512×512，不直接显示)
##   │       └── PlanetWorld (WorldGenerator)
##   │           ├── Ground (TileMapLayer)
##   │           ├── Props（visible=false，仅数据）
##   │           └── Player（小王子）
##   ├── PlanetView (ColorRect + sphere_fisheye.gdshader)
##   └── PropScreenOverlay (屏幕空间 stacked 地物)

@onready var world_viewport: SubViewport = $WorldHost/WorldViewport
@onready var world_root: WorldGenerator = $WorldHost/WorldViewport/PlanetWorld
@onready var player: Player = $WorldHost/WorldViewport/PlanetWorld/Player
@onready var planet_view: ColorRect = $PlanetView

var prop_overlay: PropScreenOverlay

func _ready() -> void:
	# 必须在任何 get_action_strength("move_*") 之前完成
	InputSetup.ensure_move_actions()

	# 视口尺寸与世界像素边长严格对齐，保证整张地图完整进入纹理
	var px := WorldConstants.VIEWPORT_PIXELS
	world_viewport.size = Vector2i(px, px)

	player.world_pixel_size = float(WorldConstants.WORLD_PIXELS)
	player.global_position = world_root.spawn_world_position()

	var material := planet_view.material as ShaderMaterial
	material.set_shader_parameter("world_tex", world_viewport.get_texture())

	# 地物屏幕叠加：必须在 PlanetView 之后，才能画在球面与星空之上
	prop_overlay = PropScreenOverlay.new()
	prop_overlay.name = "PropScreenOverlay"
	add_child(prop_overlay)
	# 等 WorldGenerator._ready 完成后再取 stacked_props
	prop_overlay.set_props(world_root.stacked_props)

	_update_shader_uniforms()

func _process(_delta: float) -> void:
	_update_shader_uniforms()

func _update_shader_uniforms() -> void:
	var material := planet_view.material as ShaderMaterial
	var player_uv := player.normalized_uv()
	material.set_shader_parameter("player_uv", player_uv)
	# 用 PlanetView 实际像素尺寸修正 aspect，保证任意窗口比例下仍是正圆
	var sz: Vector2 = planet_view.size
	if sz.x < 1.0 or sz.y < 1.0:
		sz = get_viewport_rect().size
	material.set_shader_parameter("view_size", sz)

	if prop_overlay == null:
		return
	prop_overlay.player_uv = player_uv
	prop_overlay.view_size = sz
	# 从材质读曲率/跨度，避免与 shader 默认值漂移
	var curv: Variant = material.get_shader_parameter("curvature")
	var span: Variant = material.get_shader_parameter("view_span")
	if typeof(curv) == TYPE_FLOAT or typeof(curv) == TYPE_INT:
		prop_overlay.curvature = float(curv)
	if typeof(span) == TYPE_FLOAT or typeof(span) == TYPE_INT:
		prop_overlay.view_span = float(span)
