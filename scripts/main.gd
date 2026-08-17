extends Control
## 全局总控：
##  1) 等待隐藏的 SubViewport 把地图 + 地物 + 小王子渲染完成；
##  2) 把该渲染结果（ViewportTexture）交给 PlanetView 的球面 Shader；
##  3) 每帧把玩家的归一化坐标写入 Shader，让球心始终对准小王子，
##     从而实现「相机永远跟随玩家」的视觉效果。
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
	# 视口尺寸与世界像素边长严格对齐，保证整张地图完整进入纹理
	var px := WorldConstants.VIEWPORT_PIXELS
	world_viewport.size = Vector2i(px, px)

	player.world_pixel_size = float(WorldConstants.WORLD_PIXELS)
	player.global_position = world_root.spawn_world_position()

	var material := planet_view.material as ShaderMaterial
	material.set_shader_parameter("world_tex", world_viewport.get_texture())
	_update_shader_player_uv()

func _process(_delta: float) -> void:
	_update_shader_player_uv()

func _update_shader_player_uv() -> void:
	var material := planet_view.material as ShaderMaterial
	material.set_shader_parameter("player_uv", player.normalized_uv())
