extends Control
## 全局总控：
##  1) 确保 InputMap 已注册 WASD/方向键（不依赖 project.godot 解析是否成功）；
##  2) 等待隐藏的 SubViewport 把地图 + 地物 + 小王子渲染完成；
##  3) 把该渲染结果（ViewportTexture）交给 PlanetView 的球面 Shader；
##  4) 每帧写入玩家 UV 与 PlanetView 尺寸，保证球心跟随且剪影为正圆。
##
## 场景树：
##   Main (Control，全屏)
##   ├── WorldHost (Node，仅承载隐藏渲染用的 SubViewport)
##   │   └── WorldViewport (SubViewport，512×512，不直接显示)
##   │       └── PlanetWorld (WorldGenerator)
##   │           ├── Ground (TileMapLayer)
##   │           ├── Props
##   │           └── Player（小王子）
##   └── PlanetView (ColorRect + sphere_fisheye.gdshader)

@onready var world_viewport: SubViewport = $WorldHost/WorldViewport
@onready var world_root: WorldGenerator = $WorldHost/WorldViewport/PlanetWorld
@onready var player: Player = $WorldHost/WorldViewport/PlanetWorld/Player
@onready var planet_view: ColorRect = $PlanetView

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
	_update_shader_uniforms()

func _process(_delta: float) -> void:
	_update_shader_uniforms()

func _update_shader_uniforms() -> void:
	var material := planet_view.material as ShaderMaterial
	material.set_shader_parameter("player_uv", player.normalized_uv())
	# 用 PlanetView 实际像素尺寸修正 aspect，保证任意窗口比例下仍是正圆
	var sz: Vector2 = planet_view.size
	if sz.x < 1.0 or sz.y < 1.0:
		sz = get_viewport_rect().size
	material.set_shader_parameter("view_size", sz)
